{ inputs, pkgs, mkNvimPlugin, ... }:
let
  tree-sitter-kulala-http = pkgs.tree-sitter.buildGrammar
    {
      passthru.name = "kulala_http";
      language = "kulala_http";
      version = inputs.kulala-nvim.lastModifiedDate;
      src = inputs.kulala-nvim;
      location = "lua/tree-sitter";
    };
  nvim-treesitter-full = (pkgs.vimPlugins.nvim-treesitter.withPlugins (_: [ tree-sitter-kulala-http ] ++ pkgs.vimPlugins.nvim-treesitter.allGrammars));
in
with pkgs.vimPlugins;
[

  {
    plugin = nvim-treesitter-full;
    type = "lua";
    optional = false;
    config = /*lua*/''
      require("nvim-treesitter").setup()
    '';
  }

  {
    plugin = nvim-treesitter-context;
    type = "lua";
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
    type = "lua";
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
    type = "lua";
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
