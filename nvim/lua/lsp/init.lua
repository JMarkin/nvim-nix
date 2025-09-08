--
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md

local M = {}

M.lsps = {
  -- "nginx_language_server",
  "nixd",
  "lua_ls",
  "rust_analyzer",
  "bashls",
  "vimls",
  "html",
  "cssls",
  -- "jedi_language_server",
  "ruff",
  -- "zuban",
  "ty",
  -- "basedpyright",
  "taplo",
  "ts_ls",
  "neocmake",
  "docker_language_server",
  "biome",
  "jinja_lsp",
  "golangci_lint_ls",
  "gopls",
  "vacuum",
  "yamlls",
  "jsonls",
  "clangd",
}

M.setup = function()
  for _, lsp in ipairs(M.lsps) do
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
      vim.lsp.enable(lsp, vim.g.lsp_autostart)
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
