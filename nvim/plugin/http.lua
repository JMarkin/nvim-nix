if vim.g.did_load_http_plugin then
  return
end
vim.g.did_load_http_plugin = true

lze.load({
  "kulala.nvim",
  ft = { "http", "rest" },
  after = function()
    require("kulala").setup({
      global_keymaps_prefix = "<leader>h",
      kulala_keymaps_prefix = "<leader>k",
    })
  end,
})
