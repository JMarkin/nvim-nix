local autocmd = vim.api.nvim_create_autocmd
local groupid = vim.api.nvim_create_augroup

local M = {}

M.get_size = function(path)
  local ok, stats = pcall(function()
    return vim.loop.fs_stat(path)
  end)
  if not (ok and stats) then
    return
  end
  return math.floor(0.5 + (stats.size / (1024 * 1024)))
end

M.is_text = function(path)
  -- Determine if file is text. This is not 100% proof, but good enough.
  -- Source: https://github.com/sharkdp/content_inspector
  local ok, fd = pcall(function()
    return vim.loop.fs_open(path, "r", 1)
  end)
  if not (ok and fd) then
    return false
  end
  ---@diagnostic disable-next-line: redefined-local
  local ok, bytes = pcall(function()
    return vim.loop.fs_read(fd, 1024)
  end)
  if not (ok and bytes) then
    return false
  end
  local is_text = bytes:find("\0") == nil
  vim.loop.fs_close(fd)
  return is_text
end

-- copy from https://github.com/Bekaboo/nvim/blob/master/lua/core/autocmds.lua
---@param group string
---@vararg { [1]: string|string[], [2]: vim.api.keyset.create_autocmd }
---@return nil
M.augroup = function(group, ...)
  local id = groupid(group, { clear = true })
  for _, a in ipairs({ ... }) do
    a[2].group = id
    autocmd(unpack(a))
  end
end

M.pcall_notify = function(func)
  local ok, out = pcall(func)
  if not ok then
    vim.notify_once(string.format("%s", out), vim.log.levels.DEBUG)
  end
  return out
end

M.is_not_mini = function()
  return vim.env.NVIM_MINI == nil
end

M.doau = function(pattern, data)
  vim.api.nvim_exec_autocmds("User", {
    pattern = pattern,
    data = data,
  })
end

function M.maxline(path, break_after)
  if break_after == nil then
    break_after = vim.o.synmaxcol + 1
  end
  local max = 0
  local fd = vim.uv.fs_open(path, "r", 1)
  if not fd then
    return max
  end
  local stat = vim.uv.fs_fstat(fd)
  if stat == nil then
    return max
  end
  local data = vim.uv.fs_read(fd, stat.size, nil)
  vim.uv.fs_close(fd)
  if not data then
    return max
  end

  local lines = vim.split(data, "[\r]?\n")

  for _, line in pairs(lines) do
    if max < #line then
      max = #line
    end
    if max >= break_after then
      return max
    end
  end
  return max
end

-- Returns the first element in the array that satisfies the provided testing function
M.ifind = function(tbl, func)
  for index, item in ipairs(tbl) do
    if func(item, index) then
      return item
    end
  end

  return nil
end

-- Function to merge two tables in Lua using Neovim.
function M.merge_tables(table1, table2)
  local merged_table = table1 or {} -- Ensure a valid table, even if nil
  for k, _ in pairs(table2) do
    merged_table[k] = table2[k]
  end

  -- Return the merged table.
  return merged_table
end

function M.debounce(fn, ms)
  local timer = vim.uv.new_timer()
  return function(...)
    local argv = { ... }
    timer:stop()
    timer:start(ms, 0, function()
      timer:stop()
      -- vim.schedule ensures the function runs on the main Neovim thread
      vim.schedule(function()
        fn(unpack(argv))
      end)
    end)
  end
end

-- https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/utils/api.lua
local api = {}
local CTRL_V = vim.api.nvim_replace_termcodes("<C-v>", true, true, true)
local CTRL_S = vim.api.nvim_replace_termcodes("<C-s>", true, true, true)

api.get_mode = function()
  local mode = vim.api.nvim_get_mode().mode:sub(1, 1)
  if mode == "i" then
    return "i" -- insert
  elseif mode == "v" or mode == "V" or mode == CTRL_V then
    return "x" -- visual
  elseif mode == "s" or mode == "S" or mode == CTRL_S then
    return "s" -- select
  elseif mode == "c" and vim.fn.getcmdtype() ~= "=" then
    return "c" -- cmdline
  end
end

api.is_insert_mode = function()
  return api.get_mode() == "i"
end

M.is_insert_mode = api.is_insert_mode

---Check if cursor is in syntax group
---@param group string | []string
---@return boolean
M.in_syntax_group = function(group)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  if not api.is_insert_mode() then
    col = col + 1
  end

  for _, syn_id in ipairs(vim.fn.synstack(row, col)) do
    syn_id = vim.fn.synIDtrans(syn_id) -- Resolve :highlight links
    local g = vim.fn.synIDattr(syn_id, "name")
    if type(group) == "string" and g == group then
      return true
    elseif type(group) == "table" and vim.tbl_contains(group, g) then
      return true
    end
  end

  return false
end

---Check if cursor is in treesitter capture
---@param capture string | []string
---@return boolean
M.in_treesitter_capture = function(capture)
  local buf = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1
  if vim.api.nvim_get_mode().mode == "i" then
    col = col - 1
  end

  local get_captures_at_pos = -- See neovim/neovim#20331
    require("vim.treesitter").get_captures_at_pos -- for neovim >= 0.8 or require('vim.treesitter').get_captures_at_position -- for neovim < 0.8

  local captures_at_cursor = vim.tbl_map(function(x)
    return x.capture
  end, get_captures_at_pos(buf, row, col))

  if vim.tbl_isempty(captures_at_cursor) then
    return false
  elseif type(capture) == "string" and vim.tbl_contains(captures_at_cursor, capture) then
    return true
  elseif type(capture) == "table" then
    for _, v in ipairs(capture) do
      if vim.tbl_contains(captures_at_cursor, v) then
        return true
      end
    end
  end

  return false
end

function M.shorten_path(path)
  local sep = package.config:sub(1, 1)
  local parts = {}
  for part in path:gmatch("[^" .. sep .. "]+") do
    table.insert(parts, part)
  end

  for i = 1, #parts - 2 do
    parts[i] = parts[i]:sub(1, 1)
  end

  return table.concat(parts, "_")
end

function M.get_ts(buf)
  local ok, large_buf = pcall(vim.api.nvim_buf_get_var, buf, "large_buf")

  if not ok then
    return nil
  end
  if large_buf ~= 0 then
    return nil
  end

  local parser

  ok, parser = pcall(vim.treesitter.get_parser, buf, vim.treesitter.language.get_lang(vim.bo[buf].ft))
  if not ok then
    return nil
  end
  return parser
end

M.schedule_notify = vim.schedule_wrap(vim.notify)

-- orig https://github.com/Wansmer/nvim-config/blob/main/lua/utils.lua

-- From: https://neovim.discourse.group/t/how-do-you-work-with-strings-with-multibyte-characters-in-lua/2437/4
function M.char_byte_count(s, i)
  if not s or s == "" then
    return 1
  end

  local char = string.byte(s, i or 1)

  -- Get byte count of unicode character (RFC 3629)
  if char > 0 and char <= 127 then
    return 1
  elseif char >= 194 and char <= 223 then
    return 2
  elseif char >= 224 and char <= 239 then
    return 3
  elseif char >= 240 and char <= 244 then
    return 4
  end
end

function M.char_on_pos(pos)
  pos = pos or vim.fn.getpos(".")
  return tostring(vim.fn.getline(pos[1])):sub(pos[2], pos[2])
end

---@return 'char'|'line'|'block'|nil
function M.visual_mode_type()
  return ({
    ["v"] = "char",
    ["V"] = "line",
    ["^V"] = "block",
  })[vim.fn.strtrans(vim.fn.mode())]
end

function M.get_visual_range()
  local sr, sc = unpack(vim.fn.getpos("v"), 2, 3)
  local er, ec = unpack(vim.fn.getpos("."), 2, 3)

  local mode = M.visual_mode_type()

  if sr > er then
    sr, sc, er, ec = er, ec, sr, sc
  end

  if sr == er or mode == "block" then
    sc, ec = math.min(sc, ec), math.max(sc, ec)
  end

  if mode == "line" then
    sc, ec = 0, -1 -- -1 means last character
  end

  local range = { sr, sc > 0 and sc - 1 or 0, er, ec }

  -- To correct work with non-single byte chars
  local byte_c = M.char_byte_count(M.char_on_pos({ range[3], range[4] }))
  range[4] = range[4] + ((byte_c or 1) - 1)

  return range
end

function M.split_padline(line, side)
  side = side or "both"
  local is_left = side == "both" and true or side == "left"
  local is_right = side == "both" and true or side == "right"
  local pad_left, pad_right = "", ""

  if is_left then
    local start, end_ = line:find("^%s+")
    if start then
      pad_left = line:sub(start, end_)
      line = line:sub(end_ + 1)
    end
  end

  if is_right then
    local start, end_ = line:find("%s+$")
    if start then
      pad_right = line:sub(start, end_)
      line = line:sub(1, -(#pad_right + 1))
    end
  end

  return pad_left, line, pad_right
end

function M.to_api_range(range)
  local sr, sc, er, ec = unpack(range)
  return sr - 1, sc, er - 1, ec
end

---Feedkeys with 'n' (noremap) by default
---@param f string
---@param mode? string
function M.feedkeys(f, mode)
  local term = vim.keycode(f)
  vim.api.nvim_feedkeys(term, mode or "n", true)
end

function M.lazy_rhs_cb(module, cb_name, ...)
  local args = { ... }
  return function()
    if #args == 0 then
      return require(module)[cb_name]()
    else
      return require(module)[cb_name](unpack(args))
    end
  end
end

---Clear autocmds by group and return callback to restore them
---@param group number|string Group name or id
---@return function Callback to restore cleared group's autocmds
function M.disable_autocmd(group)
  local ok, aus = pcall(vim.api.nvim_get_autocmds, { group = group })
  if ok then
    vim.api.nvim_clear_autocmds({ group = group })
    local function make_opts(au)
      local opts = {
        group = au.group,
        desc = au.desc,
        once = au.once,
        pattern = au.pattern,
      }

      if au.command ~= "" then
        opts.command = au.command
      else
        opts.callback = au.callback
      end

      return opts
    end

    return function()
      vim.defer_fn(function()
        for _, au in ipairs(aus) do
          vim.api.nvim_create_autocmd(au.event, make_opts(au))
        end
      end, 0)
    end
  else
    return function() end
  end
end

return M
