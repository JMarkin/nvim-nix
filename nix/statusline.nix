{ inputs, pkgs, mkNvimPlugin, ... }:
with pkgs.vimPlugins; [
  {
    plugin = mini-statusline;
    type = "lua";
    optional = true;
    config = /*lua*/''
      lze.load {
        "mini.statusline",
        event = vim.g.post_load_events,
        after = function()
          require("mini.statusline").setup()

          local fn = require("funcs")

          fn.augroup("disable statusline", {
            "FileType",
            {
              pattern = {'AgenticChat', 'AgenticInput', 'AgenticCode', 'AgenticFiles'},
              callback = function()
                vim.b.ministatusline_disable = true
              end,

            }
        })
        end,
      }
    '';
  }
]
