{ inputs, pkgs, mkNvimPlugin, ... }:
{
  plugins = with pkgs.vimPlugins; [
  ];

  packages = with pkgs; [
    opencode
  ];
}

