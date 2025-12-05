if vim.g.did_load_lint_plugin then
  return
end
vim.g.did_load_lint_plugin = true

local fn = require("funcs")

vim.g.linter_by_ft = {
  sql = { "codespell", "sqlfluff" },
  jinja = { "djlint" },
  htmldjango = { "djlint" },
  python = { "codespell" },
  rust = { "codespell" },
  go = { "codespell" },
}

local patterns = {}

for key, _ in pairs(vim.g.linter_by_ft) do
  table.insert(patterns, key)
end

local server = {}
local client_capabilities = {
  capabilities = {
    textDocumentSync = {
      openClose = true,
      save = true,
    },
  },
}

local running_procs_by_buf = {}

local opts = { ignore_errors = true }

local function try_lint(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    if running_procs_by_buf[bufnr] ~= nil then
      running_procs_by_buf[bufnr] = nil
    end
    return
  end

  local nvimlint = require("lint")
  local ft = vim.bo[bufnr].filetype

  local names = nvimlint._resolve_linter_by_ft(ft)

  local lookup_linter = function(name)
    local linter = nvimlint.linters[name]
    assert(linter, "Linter with name `" .. name .. "` not available")
    if type(linter) == "function" then
      linter = linter()
    end
    linter.name = linter.name or name
    return linter
  end
  local running_procs = running_procs_by_buf[bufnr] or {}
  for _, linter_name in pairs(names) do
    local linter = lookup_linter(linter_name)
    local proc = running_procs[linter.name]
    if proc then
      proc:cancel()
    end
    running_procs[linter.name] = nil
    local ok, lintproc_or_error = pcall(nvimlint.lint, linter, opts)
    if ok then
      running_procs[linter.name] = lintproc_or_error
    elseif not opts.ignore_errors then
      vim.notify(lintproc_or_error --[[@as string]], vim.log.levels.WARN)
    end
  end
  running_procs_by_buf[bufnr] = running_procs
end

function server.create(buf)
  return function()
    local srv = {}

    function srv.initialize(params, callback)
      callback(nil, client_capabilities)
    end

    srv["textDocument/didOpen"] = function(params)
      try_lint(buf)
    end
    srv["textDocument/didClose"] = function(params)
      -- try_lint(buf)
    end
    srv["textDocument/didSave"] = function(params)
      try_lint(buf)
    end

    function srv.shutdown(params, callback)
      callback(nil, nil)
    end

    return {
      request = function(method, params, callback)
        if srv[method] then
          srv[method](params, callback)
        else
          callback({ message = "Method not found: " .. method })
        end
      end,
      notify = function(method, params)
        if srv[method] then
          srv[method](params)
        end
      end,
      is_closing = function()
        return false
      end,
      terminate = function()
        client_capabilities = {}
      end,
    }
  end
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("InlineLint", { clear = true }),
  pattern = patterns,
  callback = function(args)
    local buf = args.buf
    if not vim.bo[buf].modifiable or vim.list_contains({ "terminal", "nofile" }, vim.bo[buf].buftype) then
      return
    end

    vim.lsp.start({
      name = "inline-lint",
      cmd = server.create(buf),
      root_dir = vim.uv.cwd(),
      reuse_client = function()
        return true
      end,
    })
  end,
  desc = "Inline nvim-lint autostart",
})

fn.augroup("Diagnostic", {
  "DiagnosticChanged",
  {
    callback = function()
      vim.diagnostic.setloclist({ open = false })
    end,
  },
})

vim.keymap.set("n", "<space>e", function(_)
  vim.diagnostic.setloclist({ open = false })
  require("quicker").toggle({ loclist = true })
end, {})

vim.keymap.set("n", "<space>E", function(_)
  vim.diagnostic.setqflist({ open = false })
  require("quicker").toggle()
end, {})
