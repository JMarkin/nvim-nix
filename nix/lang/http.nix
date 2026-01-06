{ inputs, pkgs, lib, mkNvimPlugin, ... }:
{
  packages = [
    pkgs.kulala-fmt
    pkgs.websocat
    pkgs.grpcurl
    pkgs.prettier
    pkgs.libxml2
  ];

  plugins = [
    pkgs.vimPlugins.kulala-nvim
  ];
  luasetup = "";
}
