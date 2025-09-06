if vim.env.NVIM_MINI ~= nil then
  return
end

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
