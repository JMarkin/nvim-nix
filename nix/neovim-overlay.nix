# This overlay, when applied to nixpkgs, adds the final neovim derivation to nixpkgs.
{ inputs }: final: prev:
with final.pkgs.lib; let
  pkgs = final;
  lib = final.pkgs.lib;

  rust-bin = inputs.rust-overlay.rust-bin;

  # Use this to create a plugin from a flake input
  mkNvimPlugin = src: pname:
    pkgs.vimUtils.buildVimPlugin {
      inherit pname src;
      version = src.lastModifiedDate;
    };

  # Make sure we use the pinned nixpkgs instance for wrapNeovimUnstable,
  # otherwise it could have an incompatible signature when applying this overlay.
  pkgs-locked = inputs.nixpkgs.legacyPackages.${pkgs.system};

  # This is the helper function that builds the Neovim derivation.
  mkNeovim = pkgs.callPackage ./mkNeovim.nix {
    inherit (pkgs-locked) wrapNeovimUnstable neovimUtils;
  };

  callPackage = (file: pkgs.callPackage file {
    inherit inputs pkgs mkNvimPlugin lib;
  });

  langs = callPackage ./lang;

  # A plugin can either be a package or an attrset, such as
  # { plugin = <plugin>; # the package, e.g. pkgs.vimPlugins.nvim-cmp
  #   config = <config>; # String; a config that will be loaded with the plugin
  #   # Boolean; Whether to automatically load the plugin as a 'start' plugin,
  #   # or as an 'opt' plugin, that can be loaded with `:packadd!`
  #   optional = <true|false>; # Default: false
  #   ...
  # }
  all-plugins = with pkgs.vimPlugins; [
    # кастыль для neovim/nix там init.vim чтобы всё обернуть в lua << END
    # последний плагин в конце должен содержать END
    {
      plugin = lze;
      optional = false;
      config = /*vim*/''
        lua << END
        _G.lze = require("lze")
        END

        lua << END
      '';
    }

    {
      plugin = alpha-nvim;
      optional = false;
      config = /*lua*/''
        require("dash")
      '';
    }
  ]
  ++ langs.plugins
  ++ (callPackage ./treesitter.nix)
  ++ (callPackage ./autocomplete.nix)
  ++ (callPackage ./statusline.nix)
  ++ (callPackage ./quickfix.nix)
  ++ (callPackage ./blink-pairs.nix)
  ++ (callPackage ./ui.nix)
  ++ (callPackage ./avante.nix)

  ++ [
    vim-polyglot
    diffview-nvim
    gitsigns-nvim
    vim-fugitive

    which-key-nvim
    better-escape-nvim
    {
      plugin = plenary-nvim;
      optional = true;
      type = "lua";
      config = /*lua*/''
        lze.load {
          "plenary.nvim",
          on_require = {"plenary.job", "plenary.path"},
        }
      '';
    }

    fzf-lua
    smart-splits-nvim

    eyeliner-nvim
    demicolon-nvim
    flash-nvim

    comment-nvim


    vim-easy-align
    treesj
    mini-splitjoin
    mini-ai
    mini-misc
    {
      plugin = mini-icons;
      optional = false;
      type = "lua";
      config = /*lua*/''
        require("mini.icons").setup()
        MiniIcons.mock_nvim_web_devicons()
      '';
    }
    {
      plugin = vim-suda;
      optional = true;
      type = "lua";
      config = /*lua*/''
        lze.load({
          "suda.vim",
          cmd = { "SudaRead", "SudaWrite" },
        })
      '';
    }
    {
      plugin = (mkNvimPlugin inputs.stay-in-place-nvim "stay-in-place.nvim");
      optional = true;
      type = "lua";
      config = /*lua*/''
        lze.load({
          "stay-in-place.nvim",
          after=function()
            require("stay-in-place").setup{
              set_keymaps = true,
              preserve_visual_selection = true,
            }
          end,
          event = "ModeChanged",
        })
      '';
    }

    {
      plugin = nvim-scissors;
      type = "lua";
      optional = true;
      config = /*lua*/''
        lze.load {
          "${nvim-scissors.pname}",
          after = function()
            require("scissors").setup{
                snippetDir = vim.fn.stdpath("config") .. "/snippets",
                jsonFormatter = "jaq",
            }
          end,
          keys = {
            {
              "<leader>Se",
              function()
                require("scissors").editSnippet()
              end,
              desc = "Snippet: Edit",
            },
            {
              "<leader>Sn",
              function()
                require("scissors").addNewSnippet()
              end,
              mode = { "n", "x", "v" },
              desc = "Snippet: New",
            },
          },
        }
      '';
    }

    { plugin = oil-nvim; optional = false; }

    {
      plugin = snacks-nvim;
      optional = false;

      config = /*lua*/''
        END
      '';
    }

  ];

  extraPackages = langs.packages ++ [
    pkgs.jaq
    # lsp features
    pkgs.fswatch

    pkgs.fixjson
    pkgs.codespell
  ];
in
{
  # This is the neovim derivation
  # returned by the overlay
  nvim-pkg = mkNeovim {
    plugins = all-plugins;
    inherit extraPackages;
  };

  # This is meant to be used within a devshell.
  # Instead of loading the lua Neovim configuration from
  # the Nix store, it is loaded from $XDG_CONFIG_HOME/nvim-dev
  nvim-dev = mkNeovim {
    plugins = all-plugins;
    inherit extraPackages;
    appName = "nvim-dev";
    wrapRc = false;
  };

  # This can be symlinked in the devShell's shellHook
  nvim-luarc-json = final.mk-luarc-json {
    plugins = all-plugins;
  };

  # You can add as many derivations as you like.
  # Use `ignoreConfigRegexes` to filter out config
  # files you would not like to include.
  #
  # For example:
  #
  # nvim-pkg-no-telescope = mkNeovim {
  #   plugins = [];
  #   ignoreConfigRegexes = [
  #     "^plugin/telescope.lua"
  #     "^ftplugin/.*.lua"
  #   ];
  #   inherit extraPackages;
  # };
}
