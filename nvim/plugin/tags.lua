if vim.g.did_load_tags_plugin then
  return
end
vim.g.did_load_tags_plugin = true

lze.load({
  "namu.nvim",
  keys = { { "<leader>st", ":Namu ctags<cr>", desc = "Tagbar" } },
  cmd = { "Namu" },
  after = function()
    require("namu").setup({
      -- Enable the modules you want
      namu_symbols = {
        enable = true,
        options = {
          row_position = "bottom10_right",
        },
      },
      namu_ctags = {
        enable = true,
        options = {
          row_position = "bottom10_right",
        },
      },
      -- Optional: Enable other modules if needed
      colorscheme = {
        enable = false,
      },
      ui_select = { enable = false }, -- vim.ui.select() wrapper
    })
  end,
})

lze.load({
  "gentags.lua",
  event = "DeferredUIEnter",
  after = function()
    require("gentags").setup({
      autostart = true,
      async = true,
      args = {
        "--extras=+r+q",
        "--exclude=\\.*",
        "--exclude=.mypy_cache",
        "--exclude=.ruff_cache",
        "--exclude=.pytest_cache",
        "--exclude=dist",
        "--exclude=target",
        "--exclude=build",
        "--exclude=.git",
        "--exclude=node_modules*",
        "--exclude=BUILD",
        "--exclude=vendor*",
        "--exclude=*.min.*",
        "--exclude=__file__",
        "--exclude=.devenv",
      },
    })
  end,
  cmd = {
    "GenCTags",
    "GenTagsEnable",
    "GenTagsDisable",
  },
})
