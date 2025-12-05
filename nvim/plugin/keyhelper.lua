if vim.g.did_load_keyhelper_plugin then
  return
end
vim.g.did_load_keyhelper_plugin = true

lze.load({
  {
    "better-escape.nvim",
    event = "DeferredUIEnter",
    after = function()
      require("better_escape").setup({
        default_mappings = false,
        mappings = {
          i = {
            j = {
              j = "<Esc>",
            },
            k = {
              k = "<Esc>",
            },
          },
          c = {},
          t = {
            j = {
              k = "<C-\\><C-n>",
              j = "<C-\\><C-n>",
            },
          },
          v = {},
          s = {},
        },
      })
    end,
  },
})
