--
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md

local M = {}

local get_lsps = function()
  return vim
    .iter(vim.api.nvim_get_runtime_file("lsp/*.lua", true))
    :filter(function(path)
      local exists, _ = string.find(path, "nvim/")
      return exists ~= nil
    end)
    :map(function(path)
      local file_name = path:match("[^/]*.lua$")
      return file_name:sub(0, #file_name - 4)
    end)
    :totable()
end

M.get_lsps = get_lsps

M.setup = function()
  local lsps = get_lsps()

  for _, lsp in ipairs(lsps) do
    local cfg = vim.lsp.config[lsp]
    if not cfg then
      vim.print(string.format("%s not configured", lsp))
      goto continue
    end

    local cmd = cfg.cmd
    if cmd == nil then
      vim.print(string.format("%s not configured: cmd nil", lsp))
      goto continue
    end

    if type(cmd) == "function" then
      goto continue
    end

    if cmd ~= nil and vim.fn.executable(cmd[1]) == 1 then
      vim.lsp.enable(lsp, vim.g.lsp_autostart)
    end

    ::continue::
  end

  -- vim.lsp.handlers["workspace/diagnostic/refresh"] = function(_, _, ctx)
  --   local ns = vim.lsp.diagnostic.get_namespace(ctx.client_id)
  --   local bufnr = vim.api.nvim_get_current_buf()
  --   vim.diagnostic.reset(ns, bufnr)
  --   return true
  -- end

  vim.diagnostic.config({
    underline = true,
    signs = true,
    virtual_text = false,
    virtual_lines = { current_line = true },
    float = true,
    -- jump = {
    --   float = true,
    --   wrap = true,
    -- },
    update_in_insert = false,
    severity_sort = true,
  })

  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
    update_in_insert = false,
  })

  require("lsp.utils").setup_autocmds()
end

return M
