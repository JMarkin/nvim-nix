{ inputs, pkgs, mkNvimPlugin, ... }:
let
  nvim-window = (mkNvimPlugin inputs.nvim-window "nvim-window");
in
with pkgs.vimPlugins; [
  {
    plugin = tabby-nvim;
    type = "lua";
    optional = true;
    config = /*lua*/''
      lze.load {
        "${tabby-nvim.pname}",
        event = "TabNew",
        after = function()
          require("tabby").setup({
            option = {
              lualine_theme = vim.g.lualine_theme or nil,
              buf_name = { mode = "tail" },
            },
          })
        end,
      }
    '';
  }
  {
    plugin = nvim-window;
    type = "lua";
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
