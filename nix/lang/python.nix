{ pkgs, ... }:
{
  packages = with pkgs; [
    python313Packages.ipython

    ruff
    ty
  ];

  plugins = [];

}
