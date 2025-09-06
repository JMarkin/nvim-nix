{ inputs, pkgs, mkNvimPlugin, ... }:

with pkgs.vimPlugins; [
  blink-cmp
  friendly-snippets
  lazydev-nvim
  neogen
  colorful-menu-nvim
  blink-compat
  cmp-nvim-tags
  (mkNvimPlugin inputs.cmp-diag-codes "cmp-diag-codes")
]
