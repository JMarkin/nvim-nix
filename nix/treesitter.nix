{ inputs, pkgs, mkNvimPlugin, ... }:
let
  kulala = pkgs.callPackage ./kulala.nix { inherit inputs pkgs; };
  # nvim-treesitter = pkgs.vimPlugins.nvim-treesitter.withAllGrammars;
  nvim-treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
    # plugins
    kulala.grammar

    # languages
    p.rust
    p.c
    p.cpp
    p.cuda
    p.python
    p.typescript
    p.javascript
    p.fish
    p.lua
    p.html
    p.htmldjango
    p.css
    p.bash
    p.vue
    p.scss
    p.sql
    p.markdown
    p.json
    p.json5
    p.jsonc
    p.graphql
    p.commonlisp
    p.latex
    p.glsl
    p.nix
    p.go
    p.gotmpl
    p.helm
    p.gomod
    p.gosum
    # conf files
    p.ssh_config
    p.jsdoc
    p.yaml
    p.toml
    p.proto
    p.http
    p.hurl
    p.make
    p.cmake
    p.dockerfile
    p.ini
    p.vim
    p.vimdoc
    p.passwd
    p.requirements
    p.hcl
    p.xml
    p.nginx
    p.tmux
    p.udev
    # tools
    p.markdown_inline
    p.jq
    p.regex
    p.query
    p.comment
    p.rst

    # git
    p.gitcommit
    p.git_rebase
    p.gitignore
    p.git_config
    p.gitattributes

  ]);
  nvim-yati = (mkNvimPlugin inputs.nvim-yati "nvim-yati").overrideAttrs
    {
      dependencies = [ nvim-treesitter ];
    };
  hlargs-nvim = (mkNvimPlugin inputs.hlargs-nvim "hlargs.nvim").overrideAttrs
    {
      dependencies = [ nvim-treesitter ];
    };
in
[

  nvim-treesitter
  pkgs.vimPlugins.nvim-treesitter-context
  nvim-yati
  hlargs-nvim
  pkgs.vimPlugins.nvim-treesitter-textobjects

]
