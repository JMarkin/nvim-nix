{ inputs, pkgs, mkNvimPlugin, ... }:
let
  system = pkgs.system;
  kulala = pkgs.callPackage ./kulala.nix { inherit inputs pkgs; };
  nvim-treesitter = pkgs.vimPlugins.nvim-treesitter.withAllGrammars.overrideAttrs (old: {
    postInstall = old.postInstall + ''
      echo $out
    '';
  });
  # nvim-yati = (mkNvimPlugin inputs.nvim-yati "nvim-yati").overrideAttrs
  #   {
  #     dependencies = [ nvim-treesitter ];
  #   };
  hlargs-nvim = (mkNvimPlugin inputs.hlargs-nvim "hlargs.nvim").overrideAttrs
    {
      dependencies = [ nvim-treesitter ];
    };
  context = pkgs.vimPlugins.nvim-treesitter-context.overrideAttrs
    {
      dependencies = [ nvim-treesitter ];
    };
  nvim-treesitter-textobjects = inputs.nvim-treesitter-main.packages.${system}.nvim-treesitter-textobjects.overrideAttrs {
    dependencies = [ nvim-treesitter ];
  };
in
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
    plugin = context;
    type = "lua";
    optional = true;
    config = /*lua*/ ''
      lze.load({
        "nvim-treesitter-context",
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
        "hlargs.nvim",
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
        "nvim-treesitter-textobjects",
        on_plugin = "nvim-treesitter-textobjects",
      })
    '';
  }
]
