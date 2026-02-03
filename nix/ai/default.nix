{ pkgs, mkNvimPlugin, lib, inputs, ... }:
let
  callPackage = (file: pkgs.callPackage file {
    inherit inputs pkgs mkNvimPlugin;
  });

  opencode = callPackage ./opencode.nix;
  # cursortab = callPackage ./cursortab.nix;
in
{
  plugins = [ ]
    ++ opencode.plugins
    # ++ miniet.plugins
  ;
  packages = [ ]
    ++ opencode.packages
    # ++ miniet.packages
  ;
}
