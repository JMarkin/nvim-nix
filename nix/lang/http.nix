{ inputs, pkgs, lib, mkNvimPlugin, ... }:
let
  kulala = pkgs.callPackage ../kulala.nix { inherit pkgs inputs; };
in
{
  packages = [
    kulala.fmt
    pkgs.websocat
    pkgs.grpcurl
  ];

  plugins = [
    kulala.nvim
  ];
}
