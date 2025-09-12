{ inputs, pkgs, ... }:
with pkgs.vimPlugins; [
  avante-nvim
  {
    plugin = blink-cmp-avante;
    type = "lua";
    optional = true;
    config = /*lua*/''
      lze.load {
        "${blink-cmp-avante.pname}",
        on_plugin = "blink.cmp",
      }
    '';
  }
]
