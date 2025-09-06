{ inputs, pkgs, mkNvimPlugin, ... }:
with pkgs.vimPlugins; [
  {
    plugin = tabby-nvim;
    type = "lua";
    optional = true;
    config = /*lua*/''
      lze.load {
        "tabby.nvim",
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
    plugin = mini-statusline;
    type = "lua";
    optional = true;
    config = /*lua*/''
      lze.load {
        "mini.statusline",
        event = vim.g.post_load_events,
        config = function()
          require("mini.statusline").setup()
        end,
      }
    '';
  }
]
