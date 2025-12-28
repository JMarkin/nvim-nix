{ inputs, pkgs, mkNvimPlugin, ... }:
with pkgs.vimPlugins;
[

  {
    plugin = nvim-treesitter;
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
