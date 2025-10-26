{ pkgs, inputs, ... }:
let
  system = pkgs.system;
  fmt = inputs.kulala-fmt.packages.${system}.default;
  kulala-nvim = inputs.kulala-nvim;
in
{
  grammar = pkgs.tree-sitter.buildGrammar {
    language = "kulala_http";
    version = kulala-nvim.lastModifiedDate;
    src = kulala-nvim;
    location = "lua/tree-sitter";
  };
  nvim = pkgs.vimPlugins.kulala-nvim.overrideAttrs (oa: {
    version = kulala-nvim.lastModifiedDate;
    src = kulala-nvim;
  });
  inherit fmt;
}
