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
        lze.load {
          'lazydev-nvim',
          on_require = "lazydev",
          ft= { "lua" }
        }
      '';
    }
  ];
}
