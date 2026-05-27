{ inputs, pkgs, mkNvimPlugin, ... }:
let
  # tree-sitter-kulala-http = pkgs.tree-sitter.buildGrammar
  #   {
  #     passthru.name = "kulala_http";
  #     language = "kulala_http";
  #     version = inputs.kulala-nvim.lastModifiedDate;
  #     src = inputs.kulala-nvim;
  #     location = "lua/tree-sitter";
  #   };
  # nvim-treesitter-full = (pkgs.vimPlugins.nvim-treesitter.withPlugins (_: [ tree-sitter-kulala-http ] ++ pkgs.vimPlugins.nvim-treesitter.allGrammars));
  nvim-treesitter-full = pkgs.vimPlugins.nvim-treesitter.withAllGrammars;
  # TODO: move from nvim-treesitter
  # nvim-treesitter-parsers = pkgs.symlinkJoin
    # {
    #   name = "nvim-treesitter-parsers";
    #   paths = with pkgs.tree-sitter-grammars;[
    #     tree-sitter-kulala-http
    #     tree-sitter-awk
    #     tree-sitter-bash
    #     tree-sitter-c
    #     tree-sitter-c-sharp
    #     tree-sitter-caddyfile
    #     tree-sitter-cmake
    #     tree-sitter-clojure
    #     tree-sitter-comment
    #     tree-sitter-commonlisp
    #     tree-sitter-cpp
    #     tree-sitter-crystal
    #     tree-sitter-css
    #     tree-sitter-csv
    #     tree-sitter-cuda
    #     tree-sitter-d
    #     tree-sitter-dart
    #     tree-sitter-dbml
    #     tree-sitter-debian
    #     tree-sitter-dockerfile
    #     tree-sitter-diff
    #     tree-sitter-erlang
    #     tree-sitter-fish
    #     tree-sitter-gdscript
    #     tree-sitter-git-config
    #     tree-sitter-git-rebase
    #     tree-sitter-gitattributes
    #     tree-sitter-gitcommit
    #     tree-sitter-gitignore
    #     tree-sitter-gleam
    #     tree-sitter-glsl
    #     tree-sitter-go
    #     tree-sitter-gotmpl
    #     tree-sitter-gomod
    #     tree-sitter-gowork
    #     tree-sitter-go-template
    #     tree-sitter-go-template-helm
    #     tree-sitter-graphql
    #     tree-sitter-hosts
    #     tree-sitter-html
    #     tree-sitter-htmldjango
    #     tree-sitter-http
    #     tree-sitter-ini
    #     tree-sitter-java
    #     tree-sitter-javascript
    #     tree-sitter-jq
    #     tree-sitter-jsdoc
    #     tree-sitter-json
    #     tree-sitter-json5
    #     tree-sitter-just
    #     tree-sitter-kotlin
    #     tree-sitter-latex
    #     tree-sitter-log
    #     tree-sitter-lua
    #     tree-sitter-make
    #     tree-sitter-markdoc
    #     tree-sitter-markdown
    #     tree-sitter-markdown-inline
    #     tree-sitter-mermaid
    #     tree-sitter-nginx
    #     tree-sitter-nim
    #     tree-sitter-nix
    #     tree-sitter-proto
    #     tree-sitter-pug
    #     tree-sitter-python
    #     tree-sitter-query
    #     tree-sitter-regex
    #     tree-sitter-rst
    #     tree-sitter-rust
    #     tree-sitter-scss
    #     tree-sitter-svelte
    #     tree-sitter-toml
    #     tree-sitter-tsx
    #     tree-sitter-typescript
    #     tree-sitter-vim
    #     tree-sitter-vue
    #     tree-sitter-wgsl
    #     tree-sitter-xml
    #     tree-sitter-yaml
    #     tree-sitter-zig
    #   ];
    # };
in
with pkgs.vimPlugins;
[

  {
    plugin = nvim-treesitter-full;
    optional = false;
    config = /*lua*/''
      require("nvim-treesitter").setup()
    '';
  }

  {
    plugin = nvim-treesitter-context;
    optional = true;
    config = /*lua*/ ''
      lze.load({
        "${nvim-treesitter-context.pname}",
        on_require = "treesitter-context",
      })
    '';
  }

  {
    plugin = hlargs-nvim;
    optional = true;
    config = /*lua*/''
      lze.load({
        "${hlargs-nvim.pname}",
        on_require = "hlargs",
      })
    '';
  }

  {
    plugin = nvim-treesitter-textobjects;
    optional = true;
    config = /*lua*/''
      lze.load({
        "${nvim-treesitter-textobjects.pname}",
        on_require = {"nvim-treesitter-textobjects", 
          "nvim-treesitter-textobjects.repeatable_move", 
          "nvim-treesitter-textobjects.move",
          "nvim-treesitter-textobjects.swap"},
      })
    '';
  }
]
