{ pkgs, mkNvimPlugin, lib, inputs, ... }:
let
  callPackage = (file: pkgs.callPackage file {
    inherit inputs pkgs mkNvimPlugin;
  });

  opencode = callPackage ./opencode.nix;
  llama = callPackage ./llama.nix;
  # miniet = callPackage ./miniet.nix;
  # cursortab = callPackage ./cursortab.nix;
in
{
  plugins = [ ]
    ++ opencode.plugins
    ++ llama.plugins
    # ++ cursortab.plugins
    # ++ miniet.plugins
  ;
  packages = [ ]
    ++ opencode.packages
    ++ llama.packages
    # ++ cursortab.packages
    # ++ miniet.packages
  ;
}
