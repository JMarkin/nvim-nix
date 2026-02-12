{ pkgs, mkNvimPlugin, lib, inputs, ... }:
let
  callPackage = (file: pkgs.callPackage file {
    inherit inputs pkgs mkNvimPlugin;
  });

  # opencode = callPackage ./opencode.nix;
  # aider = callPackage ./aider.nix;
  # cursortab = callPackage ./cursortab.nix;
in
{
  plugins = [ ]
    # ++ opencode.plugins
    # ++ aider.plugins
    # ++ miniet.plugins
  ;
  packages = [ ]
    # ++ opencode.packages
    # ++ aider.packages
    # ++ miniet.packages
  ;
}
