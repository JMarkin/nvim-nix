local json = vim.json
local uv = vim.uv
local M = {}

local function open_cache()
  local fh = io.open(M.path, "r")
  if fh then
    local data = fh:read("*a")
    fh:close()
    M.store = json.decode(data) or {}
    return
  end
  M.store = {}
end

local function save_cache()
  local json_str = json.encode(M.store)
  local tmp_path = M.path .. ".tmp"
  local f = io.open(tmp_path, "w")
  if f then
    f:write(json_str)
    f:close()
    local success = uv.fs_rename(tmp_path, M.path)
    if not success then
      os.remove(tmp_path)
    end
  end
end

function M.get(hash)
  return M.store[hash]
end

function M.set(hash, embedding)
  M.store[hash] = embedding
  save_cache()
end

function M.setup(cfg)
  M.path = cfg.cache_path
  open_cache()
end

return M
