{ pkgs, ... }:
{

  packages = with pkgs; [
    nixd
    nixpkgs-fmt
  ];

  plugins = [];
}
