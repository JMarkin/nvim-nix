if vim.g.did_load_keyhelper_plugin then
  return
end
vim.g.did_load_keyhelper_plugin = true

require("lze").load({
  {
    "which-key.nvim",
    event = "VimEnter",
    after = function()
      require("which-key").setup({
        defaults = {},
        preset = "helix",
        keys = {
          scroll_down = "<c-d>", -- binding to scroll down inside the popup
          scroll_up = "<c-e>", -- binding to scroll up inside the popup
        },
        spec = {
          {
            mode = { "n", "v" },
            { "<leader>d", group = "dap" },
            { "<leader>g", group = "git" },
            { "<leader>s", group = "search" },
            { "<leader>l", group = "lang", icon = { icon = "󱖫 ", color = "green" } },
            { "[", group = "prev" },
            { "]", group = "next" },
            { "g", group = "goto" },
            { "gz", group = "surround" },
            { "z", group = "fold" },
            { "m", group = "mark" },
            { "M", group = "mark" },
            { "dm", group = "mark" },
            { "<Leader>lc", group = "copy_as" },
            { "<Leader>lt", group = "tests" },
            { "<Leader>h", group = "http" },
            {
              "<space>b",
              group = "buffer",
              expand = function()
                return require("which-key.extras").expand.buf()
              end,
            },
          },
        },
        triggers = {
          { "<auto>", mode = "nixsotc" },
        },
      })
    end,
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer Keymaps (which-key)",
      },
      {
        "<c-w><space>",
        function()
          require("which-key").show({ keys = "<c-w>", loop = true })
        end,
        desc = "Window Hydra Mode (which-key)",
      },
    },
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)
    end,
  },
  {
    "better-escape.nvim",
    after = function()
      require("better_escape").setup({
        default_mappings = false,
        mappings = {
          i = {
            j = {
              k = "<Esc>",
              j = "<Esc>",
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
