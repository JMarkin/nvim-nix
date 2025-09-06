return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = false },
    dashboard = { enabled = false },
    explorer = { enabled = false },
    indent = { enabled = false },
    input = { enabled = true },
    notifier = {
      enabled = true,
      timeout = 1000,
      level = vim.log.levels.WARN,
    },
    picker = { enabled = false },
    quickfile = { enabled = true },
    scope = { enabled = false },
    scroll = { enabled = false },
    statuscolumn = {
      enabled = true,
      folds = {
        open = true, -- show open fold icons
        git_hl = false, -- use Git Signs hl for fold icons
      },
      refresh = 200, -- ms
    },
    words = { enabled = false },
    styles = {
      notification = {
        wo = { wrap = true }, -- Wrap notifications
      },
    },
  },
  keys = {
    {
      "<space>bd",
      desc = "Buffers: delete current",
      function()
        Snacks.bufdelete.delete()
      end,
    },
    {
      "<space>bc",
      desc = "Buffers: delete other",
      function()
        Snacks.bufdelete.other()
      end,
    },
    {
      "<leader>M",
      desc = "Notifications",
      function()
        Snacks.notifier.show_history()
      end,
    },
    {
      "<leader>N",
      desc = "Neovim News",
      function()
        Snacks.win({
          file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
          width = 0.6,
          height = 0.6,
          wo = {
            spell = false,
            wrap = false,
            signcolumn = "yes",
            statuscolumn = " ",
            conceallevel = 3,
          },
        })
      end,
    },
  },
}
