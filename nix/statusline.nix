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
        end,
      }
    '';
  }
]
