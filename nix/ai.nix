{ inputs, pkgs, ... }:
with pkgs.vimPlugins; [
  # {
  #   plugin = codecompanion-nvim.overrideAttrs (oa: {
  #     dependencies = with pkgs.vimPlugins; [
  #       codecompanion-spinner-nvim
  #       codecompanion-history-nvim
  #     ];
  #   });
  #   type = "lua";
  #   optional = false;
  # }
  {
    plugin = avante-nvim.overrideAttrs (oa: {
      dependencies = with pkgs.vimPlugins; [
        nui-nvim
        nvim-treesitter
        plenary-nvim
      ];
    });
    type = "lua";
    optional = true;
  }
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
