{ pkgs, ... }:
{

  packages = with pkgs; [
    rust-analyzer
    cargo

    graphviz
  ];


  plugins = with pkgs.vimPlugins;[
    {
      plugin = rustaceanvim;
      optional = false;
    }
  ];

}
