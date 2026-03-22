local M = {}
local success, sqlite = pcall(require, "sqlite.db")
if not success or not sqlite then
  vim.notify("RAG: sqlite.lua not available", vim.log.levels.ERROR)
end

function M.open(path)
  local db = sqlite:open(path)
  if not db then
    vim.notify("RAG: Failed to open database", vim.log.levels.ERROR)
  end
  setmetatable(db, { __index = M })
  local success, err = pcall(function()
    db:execute(".load ../../vec0")
  end)

  if not success then
    vim.notify("RAG: Failed to load sqlite-vec: " .. tostring(err), vim.log.levels.ERROR)
    return false
  end
  return db
end

function M.exec(db, sql, ...)
  return db:execute(sql, ...)
end
function M.prepare(db, sql)
  return db:prepare(sql)
end
function M.bind(stmt, idx, value)
  stmt:bind(idx, value)
end
function M.step(stmt)
  return stmt:step()
end
function M.column(stmt, i)
  return stmt:get_value(i)
end
function M.finalize(stmt)
  stmt:finalize()
end

return M
