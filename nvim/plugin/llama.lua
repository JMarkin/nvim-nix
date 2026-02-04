-- if vim.g.did_load_llama_plugin then
--   return
-- end
-- vim.g.did_load_llama_plugin = true

-- AI+ rewrite of the original vimscript `llama.vim`.
-- -------------------------------------------------------------------------

local largefiles = require("largefiles")
local LRU = require("lru")
local funcs = require("funcs")
local curl = require("curl")

local LLAMA = {}

local function set_hl(name, attrs)
  vim.api.nvim_set_hl(0, name, attrs)
end

set_hl("llama_hl_fim_hint", { fg = "#ff772f" })
set_hl("llama_hl_fim_info", { fg = "#77ff2f" })
set_hl("llama_hl_inst_src", { bg = "#554433" })
set_hl("llama_hl_inst_virt_proc", { fg = "#77ff2f" })
set_hl("llama_hl_inst_virt_gen", { fg = "#77ff2f" })
set_hl("llama_hl_inst_virt_ready", { fg = "#ff772f" })

local base_url = vim.env.LLAMA_CPP_BASE_URL or "http://127.0.0.1:8012"

LLAMA.config = {
  endpoint_fim = base_url .. "/infill",
  endpoint_inst = base_url .. "/v1/chat/completions",
  model_fim = "fim-small",
  model_inst = "gpt-oss",
  api_key = vim.env.LLAMA_CPP_API_KEY or "",
  n_prefix = 256,
  n_suffix = 64,
  n_predict = 128,
  stop_strings = {},
  t_max_prompt_ms = 500,
  t_max_predict_ms = 1000,
  show_info = 2,
  auto_fim = true,
  max_line_suffix = 8,
  max_cache_keys = 256,
  ring_n_chunks = 16,
  ring_chunk_size = 64,
  ring_scope = 1024,
  ring_update_ms = 1000,
  keymap_fim_trigger = "<c-x><c-z>",
  keymap_fim_accept_line = "<c-z>",
  keymap_fim_accept_full = "<c-f>",
  keymap_fim_accept_word = "<c-m>",
  keymap_inst_trigger = "<leader>ai",
  keymap_inst_rerun = "<leader>ar",
  keymap_inst_continue = "<leader>ac",
  keymap_inst_accept = "<Tab>",
  keymap_inst_cancel = "<Esc>",
  enable_at_startup = true,
}

local function debug_log(msg, ...)
  -- local args = { msg, ... }
  -- vim.print(args)
  -- local args = { msg, ... }
  -- vim.api.nvim_echo({ { table.concat(args, " "), "Normal" } }, true, {})
end

local cache = LRU.new(LLAMA.config.max_cache_keys)

local function cache_insert(key, value)
  cache:set(key, value)
end

local function cache_get(key)
  local r = cache:get(key)
  return r
end

local function rand(i0, i1)
  return i0 + math.random(i1 - i0 + 1)
end

local function json_decode(str)
  return vim.json.decode(str)
end

local function json_encode(tbl)
  return vim.json.encode(tbl)
end

local function hashing(str)
  return vim.fn.sha256(str)
end

local function get_lines(from, to)
  return vim.api.nvim_buf_get_lines(0, from, to, false)
end

local state = {
  enabled = false,
  fim_hint_shown = false,
  pos_x = nil,
  pos_y = nil,
  line_cur = nil,
  can_accept = false,
  content = nil,
  ring_chunks = {},
  ring_queued = {},
  ring_n_evict = 0,
  timer_fim = nil,
  t_last_move = vim.uv.hrtime(),
  current_job_fim = nil,
  inst_reqs = {},
  inst_req_id = rand(1, 999999),
  hlgroup_hint = "llama_hl_fim_hint",
  hlgroup_info = "llama_hl_fim_info",
  hlgroup_inst = "llama_hl_inst_src",
  hlgroup_inst_info = "llama_hl_inst_info",
  hlgroup_inst_virt_proc = "llama_hl_inst_virt_proc",
  hlgroup_inst_virt_gen = "llama_hl_inst_virt_gen",
  hlgroup_inst_virt_ready = "llama_hl_inst_virt_ready",
}

local function fim_hide(_)
  state.fim_hint_shown = false
  state.can_accept = false
  local bufnr = vim.api.nvim_get_current_buf()

  local ns = vim.api.nvim_create_namespace("vt_fim")
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  pcall(vim.keymap.del, "i", LLAMA.config.keymap_fim_accept_full, { buffer = bufnr })
  pcall(vim.keymap.del, "i", LLAMA.config.keymap_fim_accept_line, { buffer = bufnr })
  pcall(vim.keymap.del, "i", LLAMA.config.keymap_fim_accept_word, { buffer = bufnr })
end

local function disable()
  fim_hide()
  vim.api.nvim_clear_autocmds({ group = "llama" })
  vim.api.nvim_del_augroup_by_name("llama")

  vim.keymap.del("i", LLAMA.config.keymap_fim_trigger)
  vim.keymap.del("v", LLAMA.config.keymap_inst_trigger)
  vim.keymap.del("n", LLAMA.config.keymap_inst_rerun)
  vim.keymap.del("n", LLAMA.config.keymap_inst_continue)
  vim.keymap.del("n", LLAMA.config.keymap_inst_accept)
  vim.keymap.del("n", LLAMA.config.keymap_inst_cancel)

  state.enabled = false
  debug_log("plugin disabled")
end

local skip_fts = {
  "help",
  "man",
  "lspinfo",
  "qf",
  "notify",
  "startuptime",
  "checkhealth",
  "PlenaryTestPopup",
  "dbout",
  "gitsigns-blame",
  "tsplayground",
  "oil",
  "namu_prompt",
}

--- Autocmd creates auto-commands for the given group.
--- @param group integer|string
--- @param events string|string[]
--- @param func function
local function autocmd(group, events, func)
  vim.api.nvim_create_autocmd(events, {
    group = group,
    pattern = "*",
    callback = function(ev)
      local buf = ev.buf
      if vim.bo[buf].buftype == "" and not vim.bo[buf].modified then
        return
      end
      local ft = vim.bo[buf].ft
      if vim.tbl_contains(skip_fts, ft) then
        return
      end

      if largefiles.is_large_file(buf, true) then
        return
      end
      local bufname = vim.fn.bufname(buf)
      if vim.startswith(bufname, "term://") then
        return
      end
      func(ev)
    end,
  })
end

local function enable()
  if state.enabled then
    return
  end

  if LLAMA.config.keymap_inst_trigger ~= "" then
    vim.keymap.set("v", LLAMA.config.keymap_inst_trigger, ":LlamaInstruct<CR>", { silent = true, noremap = true })
  end
  if LLAMA.config.keymap_inst_rerun ~= "" then
    vim.keymap.set("n", LLAMA.config.keymap_inst_rerun, LLAMA.inst_rerun, { silent = true, noremap = true })
  end
  if LLAMA.config.keymap_inst_continue ~= "" then
    vim.keymap.set("n", LLAMA.config.keymap_inst_continue, LLAMA.inst_continue, { silent = true, noremap = true })
  end
  if LLAMA.config.keymap_inst_accept ~= "" then
    vim.keymap.set("n", LLAMA.config.keymap_inst_accept, LLAMA.inst_accept, { silent = true, noremap = true })
  end
  if LLAMA.config.keymap_inst_cancel ~= "" then
    vim.keymap.set("n", LLAMA.config.keymap_inst_cancel, LLAMA.inst_cancel, { silent = true, noremap = true })
  end

  -- Setup autocommands
  local group = vim.api.nvim_create_augroup("llama", { clear = true })

  if LLAMA.config.keymap_fim_trigger ~= "" then
    autocmd(group, "InsertEnter", function()
      vim.keymap.set("i", LLAMA.config.keymap_fim_trigger, function()
        LLAMA.fim_manual()
      end, { expr = true, silent = true, noremap = true })
    end)
  end

  autocmd(group, { "InsertLeavePre", "CompleteChanged", "CompleteDone" }, fim_hide)
  if LLAMA.config.auto_fim then
    autocmd(group, { "CursorMoved", "CursorMovedI" }, LLAMA.on_move)
    autocmd(group, "CursorMovedI", function(_)
      LLAMA.fim(-1, -1, true, {}, true)
    end)
  end
  autocmd(group, "TextYankPost", function(ev)
    if ev.operator == "y" then
      LLAMA.pick_chunk(ev.regcontents, false, true)
    end
  end)
  autocmd(group, { "BufEnter", "BufLeave", "BufWritePost" }, function(_)
    local pos = vim.api.nvim_win_get_cursor(0)
    local l = get_lines(
      math.max(0, pos[1] - LLAMA.config.ring_chunk_size / 2),
      math.min(vim.api.nvim_buf_line_count(0), pos[1] + LLAMA.config.ring_chunk_size / 2)
    )
    LLAMA.pick_chunk(l, true, true)
  end)

  -- Start ring buffer updater if needed
  if LLAMA.config.ring_n_chunks > 0 then
    LLAMA.ring_update()
  end

  state.enabled = true
  debug_log("plugin enabled")
end

LLAMA.enable = enable
LLAMA.disable = disable

function LLAMA.toggle()
  if state.enabled then
    disable()
  else
    enable()
  end
end

function LLAMA.toggle_auto_fim()
  if not state.enabled then
    return
  end
  LLAMA.config.auto_fim = not LLAMA.config.auto_fim
  vim.api.nvim_clear_autocmds({ group = "llama" })
  vim.api.nvim_create_augroup("llama", { clear = true })
  if LLAMA.config.auto_fim then
    autocmd("llama", { "CursorMoved", "CursorMovedI" }, LLAMA.on_move)
    autocmd("llama", "CursorMovedI", function(_)
      LLAMA.fim(-1, -1, true, {}, true)
    end)
  end
end

--- @return vim.SystemObj
local function request(url, body, opts)
  local headers = {
    ["Content-Type"] = "application/json",
  }

  if LLAMA.config.api_key ~= "" then
    headers["Authorization"] = "Bearer " .. LLAMA.config.api_key
  end

  opts = vim.tbl_deep_extend("force", opts, {
    headers = headers,
    body = json_encode(body),
  })

  return curl.post(url, opts)
end

---Computes similarity between two chunks based on common token count.
---@param c0 table<string>
---@param c1 table<string>
---@return number
local function chunk_sim(c0, c1)
  local s0 = table.concat(c0, "\n")
  local s1 = table.concat(c1, "\n")
  local tokens = {}
  for tok in s0:gmatch("%w+") do
    tokens[tok] = true
  end
  local common = 0
  for tok in s1:gmatch("%w+") do
    if tokens[tok] then
      common = common + 1
    end
  end
  local total = #c0 + #c1
  if total == 0 then
    return 1.0
  end
  return 2.0 * common / total
end

function LLAMA.pick_chunk(text, no_mod, do_evict)
  if
    no_mod
    and (
      vim.api.nvim_get_option_value("modified", { buf = 0 })
      or not vim.api.nvim_buf_is_loaded(0)
      or not vim.fn.filereadable(vim.fn.expand("%"))
    )
  then
    return
  end
  if LLAMA.config.ring_n_chunks <= 0 then
    return
  end
  if #text < 3 then
    return
  end

  local chunk, chunk_str
  if #text + 1 < LLAMA.config.ring_chunk_size then
    chunk = text
  else
    local l0 = rand(0, math.max(0, #text - LLAMA.config.ring_chunk_size / 2))
    local l1 = math.min(l0 + LLAMA.config.ring_chunk_size / 2, #text)
    chunk = {}
    for i = l0 + 1, l1 do
      table.insert(chunk, text[i])
    end
  end
  chunk_str = table.concat(chunk, "\n") .. "\n"

  -- check if already present
  for _, c in ipairs(state.ring_chunks) do
    if c.data == chunk then
      return
    end
  end
  for _, c in ipairs(state.ring_queued) do
    if c.data == chunk then
      return
    end
  end

  -- evict similar queued chunks
  for i = #state.ring_queued, 1, -1 do
    if chunk_sim(state.ring_queued[i].data, chunk) > 0.9 then
      if do_evict then
        table.remove(state.ring_queued, i)
        state.ring_n_evict = state.ring_n_evict + 1
      else
        return
      end
    end
  end
  for i = #state.ring_chunks, 1, -1 do
    if chunk_sim(state.ring_chunks[i].data, chunk) > 0.9 then
      if do_evict then
        table.remove(state.ring_chunks, i)
        state.ring_n_evict = state.ring_n_evict + 1
      else
        return
      end
    end
  end

  if #state.ring_queued == 16 then
    table.remove(state.ring_queued, 1)
  end
  table.insert(
    state.ring_queued,
    { data = chunk, str = chunk_str, time = vim.uv.hrtime(), filename = vim.fn.expand("%") }
  )
end

local function ring_get_extra()
  local extra = {}
  for _, c in ipairs(state.ring_chunks) do
    table.insert(extra, { text = c.str, time = c.time, filename = c.filename })
  end
  return extra
end

function LLAMA.ring_update()
  vim.defer_fn(LLAMA.ring_update, LLAMA.config.ring_update_ms)

  if vim.fn.mode() ~= "n" and (vim.uv.hrtime() - state.t_last_move) / 1e9 < 3 then
    return
  end
  if #state.ring_queued == 0 then
    return
  end

  if #state.ring_chunks == LLAMA.config.ring_n_chunks then
    table.remove(state.ring_chunks, 1)
  end
  table.insert(state.ring_chunks, table.remove(state.ring_queued, 1))

  local extra = ring_get_extra()
  local body = {
    id_slot = 0,
    input_prefix = "",
    input_suffix = "",
    input_extra = extra,
    prompt = "",
    n_predict = 0,
    temperature = 0.0,
    samplers = {},
    stream = false,
    cache_prompt = true,
    t_max_prompt_ms = 1,
    t_max_predict_ms = 1,
    response_fields = { "" },
  }
  if LLAMA.config.model_fim ~= "" then
    body.model = LLAMA.config.model_fim
  end

  request(LLAMA.config.endpoint_fim, body, {})
end

local function fim_ctx_local(pos_x, pos_y, prev)
  local max_y = vim.fn.line("$")
  local line_cur, line_cur_prefix, line_cur_suffix, lines_prefix, lines_suffix, indent

  if not prev or #prev == 0 then
    line_cur = vim.fn.getline(pos_y)
    line_cur_prefix = vim.fn.strpart(line_cur, 0, pos_x)
    line_cur_suffix = vim.fn.strpart(line_cur, pos_x)
    lines_prefix = vim.fn.getline(math.max(1, pos_y - LLAMA.config.n_prefix), pos_y - 1)
    lines_suffix = vim.fn.getline(pos_y + 1, math.min(max_y, pos_y + LLAMA.config.n_suffix))

    if vim.fn.match(line_cur, "^\\s*$") >= 0 then
      indent = 0
      line_cur_prefix = ""
      line_cur_suffix = ""
    else
      indent = #vim.fn.matchstr(line_cur, "^\\s*")
    end
  else
    if #prev == 1 then
      line_cur = vim.fn.getline(pos_y) .. prev[1]
    else
      line_cur = prev[#prev]
    end
    line_cur_prefix = line_cur
    line_cur_suffix = ""
    lines_prefix = vim.fn.getline(math.max(1, pos_y - LLAMA.config.n_prefix + #prev - 1), pos_y - 1)
    if #prev > 1 then
      table.insert(lines_prefix, vim.fn.getline(pos_y) .. prev[1])
      for i = 2, #prev - 1 do
        table.insert(lines_prefix, prev[i])
      end
    end
    lines_suffix = vim.fn.getline(pos_y + 1, math.min(max_y, pos_y + LLAMA.config.n_suffix))
    indent = state.indent_last
  end

  local prefix = table.concat(lines_prefix, "\n") .. "\n"
  local middle = line_cur_prefix
  local suffix = line_cur_suffix .. "\n" .. table.concat(lines_suffix, "\n") .. "\n"

  return {
    prefix = prefix,
    middle = middle,
    suffix = suffix,
    indent = indent,
    line_cur = line_cur,
    line_cur_prefix = line_cur_prefix,
    line_cur_suffix = line_cur_suffix,
  }
end

function LLAMA.fim_manual()
  if not state.enabled then
    return ""
  end
  if state.fim_hint_shown then
    LLAMA.fim_hide()
    return ""
  end
  LLAMA.fim(-1, -1, false, {}, false)
  return ""
end

local debounced_fim = funcs.debounce(function(pos_x, pos_y, prev, use_cache)
  LLAMA.fim(pos_x, pos_y, true, prev, use_cache)
end, 100)

function LLAMA.fim(pos_x, pos_y, is_auto, prev, use_cache)
  local pos = vim.api.nvim_win_get_cursor(0)
  pos_x = pos_x < 0 and pos[2] or pos_x
  pos_y = pos_y < 0 and pos[1] or pos_y

  if state.current_job_fim then
    debounced_fim(pos_x, pos_y, prev, use_cache)
    return
  end

  local ctx = fim_ctx_local(pos_x, pos_y, prev)
  local prefix, middle, suffix, indent = ctx.prefix, ctx.middle, ctx.suffix, ctx.indent

  if is_auto and #ctx.line_cur_suffix > LLAMA.config.max_line_suffix then
    return
  end

  local t_max_predict_ms = LLAMA.config.t_max_predict_ms
  if not prev or #prev == 0 then
    t_max_predict_ms = 250
  end

  local key = prefix .. middle .. "Î" .. suffix
  local hashes = { hashing(prefix .. middle .. "Î" .. suffix) }
  local prefix_trim = prefix
  for _ = 1, 3 do
    prefix_trim = (prefix_trim:gsub("^[^\n]*\n", "", 1))
    if prefix_trim == "" then
      break
    end
    key = prefix_trim .. middle .. "Î" .. suffix
    table.insert(hashes, hashing(key))
  end

  if use_cache then
    for _, h in ipairs(hashes) do
      if cache_get(h) then
        return
      end
    end
  end

  state.indent_last = indent

  local curr_line = pos[1]
  local line_count = vim.api.nvim_buf_line_count(0)
  local half_chunk = LLAMA.config.ring_chunk_size / 2

  local start_idx = math.max(0, curr_line - half_chunk - 1)
  local end_idx = math.min(line_count, curr_line + half_chunk)

  local text = get_lines(start_idx, end_idx)

  local l0 = rand(0, math.max(0, #text - LLAMA.config.ring_chunk_size / 2))
  local l1 = math.min(l0 + LLAMA.config.ring_chunk_size / 2, #text)
  local chunk = {}
  for i = l0 + 1, l1 do
    table.insert(chunk, text[i])
  end

  for i = #state.ring_chunks, 1, -1 do
    if chunk_sim(state.ring_chunks[i].data, chunk) > 0.5 then
      table.remove(state.ring_chunks, i)
      state.ring_n_evict = state.ring_n_evict + 1
    end
  end

  local extra = ring_get_extra()
  local body = {
    id_slot = 0,
    input_prefix = prefix,
    input_suffix = suffix,
    input_extra = extra,
    prompt = middle,
    n_predict = LLAMA.config.n_predict,
    stop = LLAMA.config.stop_strings,
    n_indent = indent,
    top_k = 40,
    top_p = 0.90,
    samplers = { "top_k", "top_p", "infill" },
    stream = false,
    cache_prompt = true,
    t_max_prompt_ms = LLAMA.config.t_max_prompt_ms,
    t_max_predict_ms = t_max_predict_ms,
    response_fields = {
      "content",
      "timings/prompt_n",
      "timings/prompt_ms",
      "timings/prompt_per_token_ms",
      "timings/prompt_per_second",
      "timings/predicted_n",
      "timings/predicted_ms",
      "timings/predicted_per_token_ms",
      "timings/predicted_per_second",
      "truncated",
      "tokens_cached",
    },
  }
  if LLAMA.config.model_fim ~= "" then
    body.model = LLAMA.config.model_fim
  end

  if state.current_job_fim ~= nil and state.current_job_fim.pid then
    vim.uv.kill(state.current_job_fim.pid, 15)
    state.current_job_fim = nil
  end

  state.current_job_fim = request(LLAMA.config.endpoint_fim, body, {
    stream = function(_, data)
      LLAMA.fim_on_response(hashes, _, data)
    end,
    --- @param obj vim.SystemCompleted
    on_exit = function(obj)
      if obj.code ~= 0 then
        vim.notify(obj.stderr, vim.log.levels.ERROR)
      end
      LLAMA.fim_on_exit(_, obj.code)
    end,
  })

  -- gather extra context if cursor moved a lot
  local delta_y = math.abs(pos_y - (state.pos_y_pick or 0))
  if is_auto and delta_y > 32 then
    local max_y = vim.api.nvim_buf_line_count(0)
    -- First chunk (Prefix scope)
    -- start_line: pos_y - scope - 1 (convert 1-indexed to 0-indexed)
    -- end_line: pos_y - n_prefix (already exclusive since n_prefix is usually >= 1)
    LLAMA.pick_chunk(
      get_lines(math.max(0, pos_y - LLAMA.config.ring_scope - 1), math.max(0, pos_y - LLAMA.config.n_prefix)),
      false,
      false
    )

    -- Second chunk (Suffix chunk)
    -- start_line: pos_y + n_suffix - 1 (convert 1-indexed to 0-indexed)
    -- end_line: min(max_y, pos_y + n_suffix + ring_chunk_size)
    LLAMA.pick_chunk(
      get_lines(
        math.min(max_y, pos_y + LLAMA.config.n_suffix - 1),
        math.min(max_y, pos_y + LLAMA.config.n_suffix + LLAMA.config.ring_chunk_size)
      ),
      false,
      false
    )
    state.pos_y_pick = pos_y
  end
end

local function fim_on_response(hashes, _, data)
  local raw = data
  if #raw == 0 then
    return
  end
  if not raw:match("^%s*{") or not raw:match('%"content"%s*:') then
    return
  end
  local ok, res = pcall(json_decode, raw)
  if not ok then
    return
  end
  for _, h in ipairs(hashes) do
    cache_insert(h, raw)
  end
  if not state.fim_hint_shown or not state.fim_data.can_accept then
    debug_log("fim_on_response", res.content or "")
    LLAMA.fim_try_hint()
  end
end
LLAMA.fim_on_response = vim.schedule_wrap(fim_on_response)

function LLAMA.fim_on_exit(_, _)
  state.current_job_fim = nil
end

function LLAMA.on_move(_)
  state.t_last_move = vim.uv.hrtime()
  fim_hide()
  LLAMA.fim_try_hint()
end

function LLAMA.fim_try_hint()
  if not funcs.is_insert_mode() then
    return
  end

  local pos = vim.api.nvim_win_get_cursor(0)
  local pos_x = pos[2]
  local pos_y = pos[1]

  local ctx = fim_ctx_local(pos_x, pos_y, {})
  local prefix, middle, suffix = ctx.prefix, ctx.middle, ctx.suffix
  local key = prefix .. middle .. "Î" .. suffix
  local hash = hashing(key)
  local raw = cache_get(hash)

  -- ... or if there is a cached completion nearby (10 characters behind)
  -- Looks at the previous 10 characters to see if a completion is cached. If one is found at (x,y)
  -- then it checks that the characters typed after (x,y) match up with the cached completion result.
  if not raw then
    local pm = prefix .. middle
    local best = 0
    for i = 0, 127 do
      local removed = pm:sub(-i, -1)
      local ctx_new = pm:sub(1, -i - 2) .. "Î" .. suffix
      local hash_new = hashing(ctx_new)
      local resp_cached = cache_get(hash_new)
      if resp_cached then
        local resp = json_decode(resp_cached)
        if resp.content:sub(1, i) ~= removed then
          goto continue
        end
        resp.content = resp.content:sub(i + 2)
        if #resp.content > 0 then
          local cand = json_encode(resp)
          if best == 0 then
            raw = cand
          elseif #resp.content > best then
            best = #resp.content
            raw = cand
          end
        end
      end
      ::continue::
    end
  end

  if raw then
    LLAMA.fim_render(pos_x, pos_y, raw)
    if state.fim_hint_shown then
      LLAMA.fim(pos_x, pos_y, true, state.fim_data.content, true)
    end
  end
end

-- Assumes content is a table of strings, pos_x and pos_y are 0-indexed or 1-indexed based on your caller
-- This version uses 1-indexed line numbers (pos_y) and 0-indexed column numbers (pos_x) to match Vim's getline() and col()
local function process_suggestion(content, pos_x, pos_y)
  local can_accept = true

  if #content == 0 then
    table.insert(content, "")
    can_accept = false
  end

  local line_cur = get_lines(pos_y - 1, pos_y)[1] or ""

  -- If the current line is only whitespace, trim suggestion's leading whitespace to match
  if line_cur:match("^%s*$") then
    local content_lead = content[1]:match("^%s*") or ""
    local lead_len = math.min(#content_lead, #line_cur)

    line_cur = content[1]:sub(1, lead_len)
    content[1] = content[1]:sub(lead_len + 1)
  end

  -- Split current line at cursor
  local line_cur_prefix = line_cur:sub(1, pos_x)
  local line_cur_suffix = line_cur:sub(pos_x + 1)

  -- Truncate if suggestion is empty or repeats subsequent lines
  if #content == 1 and content[1] == "" then
    content = { "" }
  elseif #content > 1 and content[1] == "" then
    local next_lines = get_lines(pos_y, pos_y + #content - 1)
    local match = true
    for i = 2, #content do
      if content[i] ~= next_lines[i - 1] then
        match = false
        break
      end
    end
    if match then
      content = { "" }
    end
  end

  -- Truncate if it repeats the suffix exactly
  if #content == 1 and content[1] == line_cur_suffix then
    content = { "" }
  end

  -- Logic for discarding predictions that repeat next non-empty line
  local cmp_y = pos_y + 1
  local line_count = vim.api.nvim_buf_line_count(0)
  while cmp_y <= line_count do
    local line = get_lines(cmp_y - 1, cmp_y)[1] or ""
    if not line:match("^%s*$") then
      break
    end
    cmp_y = cmp_y + 1
  end

  local target_line = get_lines(cmp_y - 1, cmp_y)[1] or ""
  if (line_cur_prefix .. content[1]) == target_line then
    if #content == 1 then
      content = { "" }
    elseif #content == 2 then
      local next_line = get_lines(cmp_y, cmp_y + 1)[1] or ""
      if content[2] == next_line:sub(1, #content[2]) then
        content = { "" }
      end
    elseif #content > 2 then
      local buffer_chunk = get_lines(cmp_y, cmp_y + #content - 2)
      local match = true
      for i = 2, #content - 1 do
        if content[i] ~= buffer_chunk[i - 1] then
          match = false
          break
        end
      end
      if match then
        content = { "" }
      end
    end
  end

  -- Finalize content and check if it's purely whitespace
  content[#content] = content[#content] .. line_cur_suffix
  if table.concat(content, "\n"):match("^%s*$") then
    can_accept = false
  end

  return content, can_accept, line_cur
end

function LLAMA.fim_render(pos_x, pos_y, data)
  if vim.fn.pumvisible() == 1 then
    return
  end
  local raw = data
  local can_accept = true
  local has_info = false
  local n_prompt, t_prompt_ms, s_prompt = 0, 1.0, 0
  local n_predict, t_predict_ms, s_predict = 0, 1.0, 0
  local content = {}

  local resp = json_decode(raw)
  for _, part in ipairs(vim.split(resp.content or "", "\n")) do
    table.insert(content, part)
  end
  for i = #content, 1, -1 do
    if content[i] == "" then
      table.remove(content, i)
      break
    end
  end

  local n_cached = resp.tokens_cached or 0
  local truncated = resp["timings/truncated"] or false

  if resp["timings/prompt_n"] then
    n_prompt = resp["timings/prompt_n"] or 0
    t_prompt_ms = tonumber(resp["timings/prompt_ms"] or "1.0")
    s_prompt = tonumber(resp["timings/prompt_per_second"] or "0.0")
    n_predict = resp["timings/predicted_n"] or 0
    t_predict_ms = tonumber(resp["timings/predicted_ms"] or "1.0")
    s_predict = tonumber(resp["timings/predicted_per_second"] or "0.0")
    has_info = true
  end

  local line_cur
  content, can_accept, line_cur = process_suggestion(content, pos_x, pos_y)

  debug_log("content", content)

  local bufnr = vim.api.nvim_get_current_buf()
  local id_vt_fim = vim.api.nvim_create_namespace("vt_fim")

  local info = ""
  if LLAMA.config.show_info > 0 and has_info then
    local prefix = "   "
    if truncated then
      info = string.format(
        "%s | WARNING: the context is full: %d, increase the server context size or reduce g:llama_config.ring_n_chunks",
        LLAMA.config.show_info == 2 and prefix or "llama.vim",
        n_cached
      )
    else
      info = string.format(
        "%s | c: %d, r: %d/%d, e: %d, q: %d/16, C: %d/%d | p: %d (%.2f ms, %.2f t/s) | g: %d (%.2f ms, %.2f t/s)",
        LLAMA.config.show_info == 2 and prefix or "llama.vim",
        n_cached,
        #state.ring_chunks,
        LLAMA.config.ring_n_chunks,
        state.ring_n_evict,
        #state.ring_queued,
        cache.size,
        LLAMA.config.max_cache_keys,
        n_prompt,
        t_prompt_ms,
        s_prompt,
        n_predict,
        t_predict_ms,
        s_predict
      )
    end
    if LLAMA.config.show_info == 1 then
      vim.opt_local.statusline = info
      info = ""
    end
  end

  vim.api.nvim_buf_set_extmark(bufnr, id_vt_fim, pos_y - 1, pos_x, {
    virt_text = { { content[1], "llama_hl_fim_hint" }, { info, "llama_hl_fim_info" } },
    virt_text_pos = (#content == 1 and content[1] == "") and "eol" or "overlay",
  })
  vim.api.nvim_buf_set_extmark(bufnr, id_vt_fim, pos_y - 1, 0, {
    virt_lines = vim.tbl_map(function(v)
      return { { v, "llama_hl_fim_hint" } }
    end, table.move(content, 2, #content, 1, {})),
  })

  state.fim_hint_shown = true
  local fim_data = {
    pos_x = pos_x,
    pos_y = pos_y,
    line_cur = line_cur,
    can_accept = can_accept,
    content = content,
  }
  state.fim_data = fim_data

  if can_accept then
    if LLAMA.config.keymap_fim_accept_full ~= "" then
      vim.keymap.set("i", LLAMA.config.keymap_fim_accept_full, function()
        LLAMA.fim_accept("full", fim_data)
      end, { silent = true, noremap = true })
    end
    if LLAMA.config.keymap_fim_accept_line ~= "" then
      vim.keymap.set("i", LLAMA.config.keymap_fim_accept_line, function()
        LLAMA.fim_accept("line", fim_data)
      end, { silent = true, noremap = true })
    end
    if LLAMA.config.keymap_fim_accept_word ~= "" then
      vim.keymap.set("i", LLAMA.config.keymap_fim_accept_word, function()
        LLAMA.fim_accept("word", fim_data)
      end, { silent = true, noremap = true })
    end
  end
end

--- @param accept_type string type of acceptance ("full","line","word")
--- @param fim_data table containing fim data (pos_x, pos_y, line_cur, can_accept, content)
function LLAMA.fim_accept(accept_type, fim_data)
  local pos_x, pos_y = fim_data.pos_x, fim_data.pos_y
  local line_cur = fim_data.line_cur
  local can_accept = fim_data.can_accept
  local content = fim_data.content

  if can_accept and #content > 0 then
    local word = ""
    if accept_type ~= "word" then
      vim.api.nvim_buf_set_lines(0, pos_y - 1, pos_y, false, { line_cur:sub(1, pos_x) .. content[1] })
    else
      local suffix = line_cur:sub(pos_x + 1)
      local new_part = content[1]:sub(1, -(#suffix + 1))
      word = new_part:match("^%s*%S+") or ""
      local new_line = line_cur:sub(1, pos_x) .. word .. suffix
      vim.api.nvim_buf_set_lines(0, pos_y - 1, pos_y, false, { new_line })
    end

    if #content > 1 and accept_type == "full" then
      vim.api.nvim_buf_set_lines(0, pos_y, pos_y + #content - 1, false, vim.list_slice(content, 2, #content))
    end

    if accept_type == "word" then
      vim.fn.cursor(pos_y, pos_x + #word + 1)
    elseif accept_type == "line" or #content == 1 then
      vim.fn.cursor(pos_y, pos_x + #content[1] + 1)
      if #content > 1 then
        vim.api.nvim_feedkeys("\r", "n", false)
      end
    else
      vim.fn.cursor(pos_y + #content - 1, #content[#content] + 1)
    end
  end
  fim_hide()
end

--- Builds the message payload for an inst request.
--- @param l0 integer start line number
--- @param l1 integer end line number
--- @param inst string instruction
--- @param inst_prev table|nil previous instructions
function LLAMA.inst_build(l0, l1, inst, inst_prev)
  local prefix = vim.api.nvim_buf_get_lines(0, math.max(l0 - LLAMA.config.n_prefix - 1, 0), l0 - 1, false)
  local selection = vim.api.nvim_buf_get_lines(0, l0 - 1, l1, false)
  local last_line = vim.api.nvim_buf_line_count(0)
  local suffix = vim.api.nvim_buf_get_lines(0, l1, math.min(last_line, l1 + LLAMA.config.n_suffix) + 1, false)

  local messages
  if inst_prev and #inst_prev > 0 then
    messages = vim.deepcopy(inst_prev)
  else
    local system_prompt = ""
    system_prompt = system_prompt
      .. [[You are a text-editing assistant. Respond ONLY with the result of applying INSTRUCTION to SELECTION given the CONTEXT. Maintain the existing text indentation. Do not add extra code blocks. Respond only with the modified block. If the INSTRUCTION is a question, answer it directly. Do not output any extra separators. Consider the local context before (PREFIX) and after (SUFFIX) the SELECTION.]]
    local extra = ring_get_extra()
    system_prompt = system_prompt .. "\n"
    system_prompt = system_prompt .. "--- CONTEXT     " .. string.rep("-", 40) .. "\n"
    system_prompt = system_prompt .. table.concat(extra, "\n") .. "\n"
    system_prompt = system_prompt .. "--- PREFIX      " .. string.rep("-", 40) .. "\n"
    system_prompt = system_prompt .. table.concat(prefix, "\n") .. "\n"
    system_prompt = system_prompt .. "--- SELECTION   " .. string.rep("-", 40) .. "\n"
    system_prompt = system_prompt .. table.concat(selection, "\n") .. "\n"
    system_prompt = system_prompt .. "--- SUFFIX      " .. string.rep("-", 40) .. "\n"
    system_prompt = system_prompt .. table.concat(suffix, "\n") .. "\n"

    local system_message = {
      role = "system",
      content = system_prompt,
    }
    messages = { system_message }
  end

  local user_content = ""
  if inst ~= "" then
    user_content = "INSTRUCTION: " .. inst
  end
  local user_message = { role = "user", content = user_content }
  table.insert(messages, user_message)
  return messages
end

--- @param l0 integer start line number
--- @param l1 integer end line number
function LLAMA.inst(l0, l1)
  local req_id = state.inst_req_id
  state.inst_req_id = state.inst_req_id + 1

  local messages = LLAMA.inst_build(l0, l1, "", nil)

  local body = {
    id_slot = req_id,
    messages = messages,
    samplers = {},
    n_predict = 0,
    stream = false,
    cache_prompt = true,
    response_fields = { "" },
  }
  if LLAMA.config.model_inst ~= "" then
    body.model = LLAMA.config.model_inst
  end

  local bufnr = vim.api.nvim_get_current_buf()

  local req = {
    id = req_id,
    bufnr = bufnr,
    range = { l0, l1 },
    status = "proc",
    result = "",
    think = "",
    inst_prev = {},
    job = nil,
    n_gen = 0,
    extmark = -1,
    extmark_virt = -1,
  }
  state.inst_reqs[req_id] = req

  -- highlight selection
  local ns = vim.api.nvim_create_namespace("vt_inst")
  req.extmark = vim.api.nvim_buf_set_extmark(bufnr, ns, l0 - 1, 0, {
    end_row = l1 - 1,
    end_col = #vim.fn.getline(l1),
    hl_group = "llama_hl_inst_src",
  })
  req.inst = ""
  LLAMA.inst_update(req.id, "proc")

  request(LLAMA.config.endpoint_inst, body, {
    on_exit = vim.schedule_wrap(function(_)
      local inst = vim.fn.input("Instruction: ")
      if inst == "" then
        return
      end
      debug_log("inst_send | " .. inst)
      req.inst = inst
      LLAMA.inst_update(req.id, "proc")
      req.inst_prev = LLAMA.inst_build(l0, l1, inst)
      LLAMA.inst_update(req.id, "proc")
      LLAMA.inst_send(req.id, req.inst_prev)
    end),
  })
end

function LLAMA.inst_send(req_id, messages)
  debug_log("inst_send", messages)
  local req = state.inst_reqs[req_id]
  local body = {
    id_slot = req_id,
    messages = messages,
    stream = true,
    cache_prompt = true,
  }
  if LLAMA.config.model_inst ~= "" then
    body.model = LLAMA.config.model_inst
  end
  req.job = request(LLAMA.config.endpoint_inst, body, {
    stream = function(_, data)
      LLAMA.inst_on_response(req_id, data)
    end,
    --- @param obj vim.SystemCompleted
    on_exit = function(obj)
      if obj.code ~= 0 then
        vim.notify(obj.stderr, vim.log.levels.ERROR)
      end
      LLAMA.inst_on_exit(req_id, obj.code)
    end,
  })
  print(req.job)
end

function LLAMA.inst_update_pos(req)
  -- Update position if buffer moved
  local ns = vim.api.nvim_create_namespace("vt_inst")
  local pos = vim.api.nvim_buf_get_extmark_by_id(req.bufnr, ns, req.extmark, {})
  if not pos then
    return
  end
  local line = pos[1] + 1
  req.range[2] = line + (req.range[2] or 0) - req.range[1]
  req.range[1] = line
end

function LLAMA.inst_update(req_id, status)
  local req = state.inst_reqs[req_id]
  if not req then
    return
  end
  req.status = status
  local ns = vim.api.nvim_create_namespace("vt_inst")
  LLAMA.inst_update_pos(req)

  local inst_trunc = req.inst
  if #inst_trunc > 128 then
    inst_trunc = inst_trunc:sub(1, 127) .. "..."
  end
  local hl, virt_lines
  local sep = "====================================="
  if status == "ready" then
    hl = "llama_hl_inst_virt_ready"
    virt_lines = { { { sep, hl } } }
    for _, ln in ipairs(vim.split(req.result, "\n")) do
      table.insert(virt_lines, { { ln, hl } })
    end
  elseif status == "proc" then
    hl = "llama_hl_inst_virt_proc"
    virt_lines = {
      { { sep, hl } },
      { { string.format("Endpoint:    %s", LLAMA.config.endpoint_inst), hl } },
      { { string.format("Model:       %s", LLAMA.config.model_inst), hl } },
      { { string.format("Instruction: %s", inst_trunc), hl } },
      { { "Processing ...", hl } },
    }
  elseif status == "gen" then
    local preview = req.result:gsub(".*\n%s*", "")
    if #req.result == 0 and #req.think == 0 then
      preview = "[thinking]"
    elseif #req.result == 0 and #req.think ~= 0 then
      preview = req.think:gsub(".*\n%s*", "")
    end
    hl = "llama_hl_inst_virt_gen"
    virt_lines = {
      { { sep, hl } },
      { { string.format("Endpoint:    %s", LLAMA.config.endpoint_inst), hl } },
      { { string.format("Model:       %s", LLAMA.config.model_inst), hl } },
      { { string.format("Instruction: %s", inst_trunc), hl } },
      { { string.format("Generating:  %4d tokens | %s", req.n_gen, preview), hl } },
    }
  end

  if virt_lines and #virt_lines > 0 then
    table.insert(virt_lines, { { sep, hl } })
    local opts = { virt_lines = virt_lines }
    if req.extmark_virt ~= -1 then
      opts.id = req.extmark_virt
    end
    req.extmark_virt = vim.api.nvim_buf_set_extmark(req.bufnr, ns, req.range[2] - 1, 0, opts)
  end
end

--- @param req_id integer request id
--- @param data string response data
local function inst_on_response(req_id, data)
  if not data then
    return
  end
  local lines = vim.split(data, "\n")
  if #lines == 0 then
    return
  end

  local content = ""
  local thinking = ""
  for _, line in ipairs(lines) do
    if #line > 6 and vim.startswith(line, "data: ") then
      line = line:sub(7)
    end
    if line == "" or line:match("^%s*$") then
      goto continue
    end
    local ok, resp = pcall(json_decode, line)
    if ok then
      local choices = resp.choices or {}
      local delta
      if choices[1] and choices[1].delta then
        delta = choices[1].delta
        if delta.content then
          if type(delta.content) == "string" then
            content = content .. delta.content
          end
        end
        if delta.reasoning_content then
          if type(delta.reasoning_content) == "string" then
            thinking = thinking .. delta.reasoning_content
          end
        end
      elseif choices[1] and choices[1].message then
        delta = choices[1].message.content
        if type(delta) == "string" then
          content = content .. delta
        end
      end
    else
      debug_log("inst_on_response parse error", line)
    end
    ::continue::
  end

  local req = state.inst_reqs[req_id]
  if not req then
    return
  end
  LLAMA.inst_update(req_id, "gen")
  if thinking ~= "" then
    req.think = req.think .. thinking
    req.n_gen = req.n_gen + 1
  end
  if content ~= "" then
    req.result = req.result .. content
    req.n_gen = req.n_gen + 1
  end
end
LLAMA.inst_on_response = vim.schedule_wrap(inst_on_response)

local function inst_on_exit(req_id, code)
  if code ~= 0 and code ~= nil then
    LLAMA.inst_remove(req_id)
    return
  end
  local req = state.inst_reqs[req_id]
  if not req then
    return
  end
  LLAMA.inst_update(req_id, "ready")
  table.insert(req.inst_prev, { role = "assistant", content = req.result })
end
LLAMA.inst_on_exit = vim.schedule_wrap(inst_on_exit)

--- Removes an instantiated request and cleans up the buffer.
--- @param req_id number request id
--- @return nil
function LLAMA.inst_remove(req_id)
  local req = state.inst_reqs[req_id]
  if not req then
    return
  end
  local ns = vim.api.nvim_create_namespace("vt_inst")
  vim.api.nvim_buf_del_extmark(req.bufnr, ns, req.extmark)
  if req.extmark_virt ~= -1 then
    vim.api.nvim_buf_del_extmark(req.bufnr, ns, req.extmark_virt)
  end
  if req.job ~= nil and req.job.pid then
    vim.uv.kill(req.job.pid, 15)
    req.job = nil
  end
  state.inst_reqs[req_id] = nil
end

--- Replaces the selected lines in the buffer with the given result text.
--- This function is called after an LLM request has finished.
--- @param bufnr number buffer number
--- @param l0 integer start line (1-based)
--- @param l1 integer end line (1-based)
--- @param result string replacement text
--- @return nil
function LLAMA.inst_callback(bufnr, l0, l1, result)
  local result_lines = vim.split(result, "\n", { stub = true, trimempty = true })
  while #result_lines > 0 and result_lines[#result_lines] == "" do
    table.remove(result_lines)
  end
  vim.api.nvim_buf_set_lines(bufnr, l0 - 1, l1, false, result_lines)
end

function LLAMA.inst_accept()
  local line = vim.fn.line(".")
  for _, req in pairs(state.inst_reqs) do
    if req.status == "ready" then
      LLAMA.inst_update_pos(req)
      if line >= req.range[1] and line <= req.range[2] then
        LLAMA.inst_remove(req.id)
        LLAMA.inst_callback(req.bufnr, req.range[1], req.range[2], req.result)
        return
      end
    end
  end
  vim.api.nvim_feedkeys("\t", "n", false)
end

function LLAMA.inst_cancel()
  local line = vim.fn.line(".")
  for _, req in pairs(state.inst_reqs) do
    if line >= req.range[1] and line <= req.range[2] then
      LLAMA.inst_remove(req.id)
      return
    end
  end
end

function LLAMA.inst_rerun()
  local lnum = vim.fn.line(".")
  for _, req in pairs(state.inst_reqs) do
    LLAMA.inst_update_pos(req)
    if req.status == "ready" and lnum >= req.range[1] and lnum <= req.range[2] then
      debug_log("inst_rerun")
      req.result = ""
      req.status = "proc"
      req.n_gen = 0
      table.remove(req.inst_prev)
      LLAMA.inst_update(req.id, "proc")
      LLAMA.inst_send(req.id, req.inst_prev)
      return
    end
  end
end

function LLAMA.inst_continue()
  local lnum = vim.fn.line(".")
  for _, req in pairs(state.inst_reqs) do
    LLAMA.inst_update_pos(req)
    if req.status == "ready" and lnum >= req.range[1] and lnum <= req.range[2] then
      local inst = vim.fn.input("Next instruction: ")
      if inst == "" then
        return
      end
      debug_log("inst_continue | " .. inst)
      req.result = ""
      req.status = "proc"
      req.inst = inst
      req.n_gen = 0
      LLAMA.inst_update(req.id, "proc")
      req.inst_prev = LLAMA.inst_build(req.range[1], req.range[2], inst, req.inst_prev)
      LLAMA.inst_send(req.id, req.inst_prev)
      return
    end
  end
end

vim.api.nvim_create_user_command("LlamaEnable", function()
  LLAMA.enable()
end, {})
vim.api.nvim_create_user_command("LlamaDisable", function()
  LLAMA.disable()
end, {})
vim.api.nvim_create_user_command("LlamaToggle", function()
  LLAMA.toggle()
end, {})
vim.api.nvim_create_user_command("LlamaToggleAutoFim", function()
  LLAMA.toggle_auto_fim()
end, {})
vim.api.nvim_create_user_command("LlamaInstruct", function(opts)
  LLAMA.inst(opts.line1, opts.line2)
end, { range = true })
vim.api.nvim_create_user_command("LlamaInstructContinue", function()
  LLAMA.inst_continue()
end, {})

enable()
