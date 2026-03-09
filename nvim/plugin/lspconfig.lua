if vim.g.did_load_lspconfig_plugin then
  return
end
vim.g.did_load_lspconfig_plugin = true

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

local gr = augroup("lspconfig", { clear = true })

-- orig https://github.com/neovim/nvim-lspconfig/blob/master/plugin/lspconfig.lua

vim.lsp.log.set_level(vim.log.levels.OFF)

vim.api.nvim_create_user_command("LspDebug", function()
  vim.lsp.log.set_level(vim.log.levels.WARN)
end, { desc = "enable lsp log" })

autocmd(vim.g.pre_load_events, {
  pattern = "*",
  group = gr,
  once = true,
  callback = function()
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

    -- vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
    --   update_in_insert = false,
    -- })

    require("lsp.utils").setup_autocmds()
  end,
})
