{ pkgs, mkNvimPlugin, inputs, ... }:
let
  callPackage = (file: pkgs.callPackage file {
    inherit inputs pkgs mkNvimPlugin;
  });
  unsorted = callPackage ./unsorted.nix;
  go = callPackage ./go.nix;
  lua = callPackage ./lua.nix;
  rust = callPackage ./rust.nix;
  nix = callPackage ./nix.nix;
  sql = callPackage ./sql.nix;
  python = callPackage ./python.nix;

  langs = [ unsorted go lua rust nix sql python ];
in
{
  plugins = builtins.concatMap (x: x.plugins) langs;
  packages = builtins.concatMap (x: x.packages) langs;
}
