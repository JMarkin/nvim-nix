if vim.g.did_load_lspconfig_plugin then
  return
end
vim.g.did_load_lspconfig_plugin = true

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

local gr = augroup("lspconfig", { clear = true })

autocmd(vim.g.pre_load_events, {
  pattern = "*",
  group = gr,
  once = true,
  callback = function()
    require("lsp").setup()
  end,
})
