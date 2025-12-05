# This overlay, when applied to nixpkgs, adds the final neovim derivation to nixpkgs.
{ inputs }: final: prev:
with final.pkgs.lib; let
  pkgs = final;
  lib = final.pkgs.lib;

  # Use this to create a plugin from a flake input
  mkNvimPlugin = src: pname:
    pkgs.vimUtils.buildVimPlugin {
      inherit pname src;
      version = src.lastModifiedDate;
    };

  mkNvimPluginNoCheck = src: pname:
    pkgs.vimUtils.buildVimPlugin {
      inherit pname src;
      version = src.lastModifiedDate;
      doCheck = false;
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

  stayinpalce = (mkNvimPlugin inputs.stay-in-place-nvim "stay-in-place.nvim");

  toggle_plugins = val: /*vim*/''
    let g:did_load_blink_plugin = v:${val}
    let g:did_load_comment_plugin = v:${val}
    let g:did_load_format_plugin = v:${val}
    let g:did_load_git_plugin = v:${val}
    let g:did_load_jumps_plugin = v:${val}
    let g:did_load_keyhelper_plugin = v:${val}
    let g:did_load_lint_plugin = v:${val}
    let g:did_load_lspconfig_plugin = v:${val}
    let g:did_load_mini_plugin = v:${val}
    let g:did_load_snacks_plugin = v:${val}
    let g:did_load_smart_plugin = v:${val}
    let g:did_load_split_join_plugin = v:${val}
    let g:did_load_tags_plugin = v:${val}
    let g:did_load_treesitter_plugin = v:${val}
    let g:did_load_ui_plugins = v:${val}
  '';


  minimal-plugins = with pkgs.vimPlugins; [
    # кастыль для neovim/nix там init.vim чтобы всё обернуть в lua << END
    # последний плагин в конце должен содержать END
    vim-polyglot
    {
      plugin = lze;
      optional = false;
      config = /*vim*/''
        lua << END
        _G.lze = require("lze")
        END
        ${toggle_plugins "true"}
        lua << END
      '';
    }
    {
      plugin = smartyank-nvim;
      optional = true;
      type = "lua";
      config = /*lua*/''
        lze.load {
          "${smartyank-nvim.pname}",
          event = "ModeChanged",
          after = function()
            require("smartyank").setup({
              highlight = {
                enabled = true, -- highlight yanked text
                timeout = 100,
              },
            })
            vim.api.nvim_create_autocmd("FocusGained", {
              callback = function()
                local loaded_content = vim.fn.getreg("+")
                if loaded_content ~= "" then
                  vim.fn.setreg('"', loaded_content)
                end
              end,
            })
          end
        }
      '';
    }
    fzf-lua
    {
      plugin = vim-suda;
      optional = true;
      type = "lua";
      config = /*lua*/''
        lze.load({
          "${vim-suda.pname}",
          cmd = { "SudaRead", "SudaWrite" },
        })
      '';
    }
    {
      plugin = stayinpalce;
      optional = true;
      type = "lua";
      config = /*lua*/''
        lze.load({
          "${stayinpalce.pname}",
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
      plugin = indent-o-matic;
      optional = false;
    }

    {
      plugin = (mkNvimPlugin inputs.oil-nvim "oil.nvim");
      optional = false;

      config = /*vim*/''
        END
      '';
    }
  ];

  smallset-plugins = minimal-plugins
    ++ (with pkgs.vimPlugins; [
    {
      plugin = vim-fugitive;
      optional = true;
      type = "lua";
      config = /*vim*/''
        let g:did_load_mini_plugin = v:false
        let g:did_load_smart_plugin = v:false
        let g:did_load_snacks_plugin = v:false
        let g:did_load_comment_plugin = v:false
        let g:did_load_treesitter_plugin = v:false

        lua << END
        lze.load {
          "${vim-fugitive.pname}",
          cmd = {
            "Git",
          },
        }
      '';
    }
    {
      plugin = nvim-notify;
      optional = false;
      type = "lua";
      config = /*lua*/ ''
        local notif = require("notify")
        notif.setup({
            timeout = 1000,
            stages = "static",
            level = vim.log.levels.INFO,
            top_down = true,
        })
        vim.notify = notif

      '';
    }
  ])
    ++ (callPackage ./treesitter.nix)
    ++ (callPackage ./statusline.nix)
    ++ (callPackage ./windows.nix)
    ++ (callPackage ./quickfix.nix)

    ++ (with pkgs.vimPlugins; [


    {
      plugin = plenary-nvim;
      optional = true;
      type = "lua";
      config = /*lua*/''
        lze.load {
          "${plenary-nvim.pname}",
          on_require = {"plenary.job", "plenary.path"},
        }
      '';
    }

    (mkNvimPluginNoCheck inputs.smart-splits-nvim "smart-splits.nvim")
    comment-nvim
    {
      plugin = mini-misc;
      optional = false;
      type = "lua";
    }
    mini-ai
    {
      plugin = mini-icons;
      optional = false;
      type = "lua";
      config = /*lua*/''
        require("mini.icons").setup()
        MiniIcons.mock_nvim_web_devicons()
        END
      '';
    }

  ]);

  all-plugins = smallset-plugins ++ (
    with pkgs.vimPlugins;
    [
      {
        plugin = which-key-nvim;
        optional = true;
        config = /*vim*/''
          ${toggle_plugins "false"}

          lua << END
        '';
      }
    ]
  )
    ++ (callPackage ./ai.nix)
    ++ (callPackage ./autocomplete.nix)
    ++ (callPackage ./blink-pairs.nix)
    ++ (callPackage ./ui.nix)
    ++ langs.plugins
    ++ (
    with pkgs.vimPlugins; [
      eyeliner-nvim
      demicolon-nvim
      flash-nvim

      vim-easy-align
      treesj
      mini-splitjoin

      which-key-nvim
      better-escape-nvim

      diffview-nvim
      gitsigns-nvim

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
          END
        '';
      }
      # vim plugins
      { plugin = vim-test; optional = false; type = "vim"; }
    ]
  );

  extraPackages = langs.packages ++ [
    pkgs.jaq
    pkgs.fswatch

    pkgs.fixjson
    pkgs.codespell
  ];
in
{

  codingPackages = pkgs.buildEnv {
    name = "coding-packages";
    paths = extraPackages;
    pathsToLink = [ "/bin" "/share" ];
  };
  # This is the neovim derivation
  # returned by the overlay
  nvim-pkg = mkNeovim {
    plugins = all-plugins;
    inherit extraPackages;
  };

  nvim-small = mkNeovim {
    plugins = smallset-plugins;
    ignoreConfigRegexes = [
      "^lsp/.*.lua"
    ];
  };

  nvim-minimal = mkNeovim {
    plugins = minimal-plugins;
    ignoreConfigRegexes = [
      "^lsp/.*.lua"
    ];
  };

  # This is meant to be used within a devshell.
  # Instead of loading the lua Neovim configuration from
  # the Nix store, it is loaded from $XDG_CONFIG_HOME/nvim-dev
  nvim-dev = mkNeovim {
    plugins = all-plugins;
    inherit extraPackages;
    appName = "nvim-dev";
    wrapRc = true;
  };

  nvim-dev-small = mkNeovim {
    plugins = smallset-plugins;
    appName = "nvim-dev-small";
    wrapRc = true;
    ignoreConfigRegexes = [
      "^lsp/.*.lua"
    ];
  };

  nvim-dev-minimal = mkNeovim {
    plugins = minimal-plugins;
    appName = "nvim-dev-minimal";
    wrapRc = true;
    ignoreConfigRegexes = [
      "^lsp/.*.lua"
    ];
  };

  # This can be symlinked in the devShell's shellHook
  nvim-luarc-json = final.mk-luarc-json {
    plugins = all-plugins;
    lua-version = "jit51";
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
