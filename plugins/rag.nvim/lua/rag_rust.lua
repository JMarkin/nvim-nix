local api = vim.api
local fn = vim.fn

local M = {}

local lib = nil
local rag_engine = nil

function M.setup(user_opts)
  local cfg = require("rag.config")
  cfg.setup(user_opts)

  -- Load the Rust library
  local success, err = pcall(function()
    lib = ffi.load("librag")
  end)

  if not success then
    vim.notify("RAG: Failed to load Rust library - " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  -- Build the library if not already built
  local build_script = debug.getinfo(1, "S").source:sub(2):gsub("lua/rag.lua", "build.lua")
  if fn.filereadable(build_script) == 1 then
    dofile(build_script)
  end

  -- Initialize the Rust engine
  local config_json = vim.json.encode(cfg.get_config())
  local config_ptr = ffi.new("const char *", config_json)

  rag_engine = lib.rag_engine_new(config_ptr)

  if not rag_engine then
    vim.notify("RAG: Failed to initialize Rust engine", vim.log.levels.ERROR)
    return
  end

  -- Create commands
  api.nvim_create_user_command("RagIndex", function()
    M.index()
  end, {
    desc = "RAG: Index all files in project"
  })

  api.nvim_create_user_command("RagReindex", function()
    M.reindex()
  end, {
    desc = "RAG: Full reindex"
  })

  api.nvim_create_user_command("RagSearch", function(opts)
    local query = opts.args
    local n = tonumber(opts.count) or 4
    M.search(query, n)
  end, {
    nargs = 1,
    complete = function()
      return { "main", "todo", "fixme" }
    end,
    desc = "RAG: Search for code chunks"
  })

  -- Create autocmd for automatic updates
  api.nvim_create_autocmd("BufWritePost", {
    callback = function()
      M.update_on_write()
    end,
    desc = "RAG: Update embeddings on file write"
  })
end

function M.index()
  if not rag_engine then
    return
  end

  local filepath = fn.expand("%:p")
  if not filepath or filepath == "" then
    return
  end

  local success, err = pcall(function()
    local path_ptr = ffi.new("const char *", filepath)
    lib.rag_engine_index_file(rag_engine, path_ptr)
  end)

  if not success then
    vim.notify("RAG: Index failed - " .. tostring(err), vim.log.levels.ERROR)
  end
end

function M.reindex()
  if not rag_engine then
    return
  end

  local success, err = pcall(function()
    lib.rag_engine_reindex(rag_engine)
  end)

  if not success then
    vim.notify("RAG: Reindex failed - " .. tostring(err), vim.log.levels.ERROR)
  end
end

function M.search(query, n)
  if not rag_engine then
    return
  end

  local success, err = pcall(function()
    local query_ptr = ffi.new("const char *", query)
    local results_ptr = lib.rag_engine_search(rag_engine, query_ptr, n)

    if results_ptr == nil then
      vim.notify("RAG: No results found", vim.log.levels.INFO)
      return
    end

    local qf = {}

    -- Process results
    for i = 0, n - 1 do
      local result = ffi.C.cast("struct SearchResult *", results_ptr + i * ffi.sizeof("SearchResult"))

      local snippet = string.match(result.chunk_text, "^%s*(.-)%s*$")
      if #snippet > 80 then
        snippet = snippet:sub(1, 80) .. "…"
      end

      table.insert(qf, {
        filename = string.gsub(result.file_path, "^" .. fn.expand("%:p:h") .. "/", ""),
        lnum = result.line_no,
        col = 1,
        text = string.format("%s:%d – %s … (dist=%0.3f)", result.file_path, result.line_no, snippet, result.distance),
      })
    end

    fn.setqflist(qf, " ", { title = "RAG Search Results" })
    fn.copen()

    vim.notify(string.format("RAG: %d results shown", #qf), vim.log.levels.INFO)
  end)

  if not success then
    vim.notify("RAG: Search failed - " .. tostring(err), vim.log.levels.ERROR)
  end
end

function M.update_on_write()
  if not rag_engine then
    return
  end

  local filepath = fn.expand("%:p")
  if not filepath or filepath == "" then
    return
  end

  local success, err = pcall(function()
    local path_ptr = ffi.new("const char *", filepath)
    lib.rag_engine_update_on_write(rag_engine, path_ptr)
  end)

  if not success then
    vim.notify("RAG: Update failed - " .. tostring(err), vim.log.levels.WARN)
  end
end

return M