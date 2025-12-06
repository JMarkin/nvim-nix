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
        on_plugin = "nvim-treesitter-textobjects",
      })
    '';
  }
]
