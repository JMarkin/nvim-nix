{ pkgs, ... }:
{

  packages = with pkgs; [
    lua-language-server
    stylua
  ];

  plugins = with pkgs.vimPlugins;[
    {
      plugin = lazydev-nvim;
      optional = true;
      type = "lua";
      config = /*lua*/''
        require('lze').load {
          'lazydev-nvim',
          ft= { "lua" }
        }
      '';
    }
  ];
}
