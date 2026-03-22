{ inputs, pkgs, mkNvimPlugin, ... }:
with pkgs.vimPlugins; [
  {
    plugin = tabby-nvim;
    optional = true;
    config = /*lua*/''
      lze.load({
        "${tabby-nvim.pname}",
        event = "TabNew",
        after = function()
          require("tabby").setup({
            preset = "tab_only",
            option = {
              lualine_theme = vim.g.lualine_theme or nil,
            },
          })
        end,
      })
    '';
  }
  {
    plugin = nvim-window;
    optional = true;
    config = /*lua*/''
      lze.load {
        "${nvim-window.pname}",
        keys = {
            { "<space>w", "<cmd>lua require('nvim-window').pick()<cr>", desc = "nvim-window: Jump to window" },
        },
        after = function()
          require('nvim-window').setup({})
        end,
      }
    '';
  }
]
