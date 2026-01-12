{ pkgs
, inputs
, ...
}:
let
  system = pkgs.system;
  blink-pairs = inputs.blink-pairs.packages.${system}.blink-pairs;
in
[
  {
    plugin = blink-pairs;
    type = "lua";
    optional = true;
    config = /*lua*/''
      lze.load{
      "${blink-pairs.pname}",
      event = vim.g.post_load_events,
      after = function() 
          require("blink.pairs").setup{
            mappings = {
              -- you can call require("blink.pairs.mappings").enable() and require("blink.pairs.mappings").disable() to enable/disable mappings at runtime
              enabled = false,
              -- see the defaults: https://github.com/Saghen/blink.pairs/blob/main/lua/blink/pairs/config/mappings.lua#L10
              pairs = {},
            },
            highlights = {
              enabled = true,
              groups = vim.g.rainbow_delimiters_highlight,
              matchparen = {
                enabled = true,
                group = "MatchParen",
              },
            },
            debug = false,
          }
        end
      }
    '';
  }
]
