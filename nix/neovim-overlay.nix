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

  neovim-nightly = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;

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
    let g:did_load_smart_plugin = v:${val}
    let g:did_load_split_join_plugin = v:${val}
    let g:did_load_tags_plugin = v:${val}
    let g:did_load_treesitter_plugin = v:${val}
    let g:did_load_ui_plugins = v:${val}
    let g:did_load_llama_plugins = v:${val}
  '';

  minimal-packages = with pkgs; [
    curl
    fixjson
    fswatch
  ];
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
              validate_yank = false,
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
    # {
    #   plugin = stayinpalce;
    #   optional = true;
    #   type = "lua";
    #   config = /*lua*/''
    #     lze.load({
    #       "${stayinpalce.pname}",
    #       after=function()
    #         require("stay-in-place").setup{
    #           set_keymaps = true,
    #           preserve_visual_selection = true,
    #         }
    #       end,
    #       event = "ModeChanged",
    #     })
    #   '';
    # }

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

  small-packages = with pkgs; [
    jaq
    codespell
  ] ++ minimal-packages;
  smallset-plugins = minimal-plugins
    ++ (with pkgs.vimPlugins; [
    {
      plugin = vim-fugitive;
      optional = true;
      type = "lua";
      config = /*vim*/''
        let g:did_load_mini_plugin = v:false
        let g:did_load_smart_plugin = v:false
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
  ])
    ++ (callPackage ./treesitter.nix)
    ++ (callPackage ./statusline.nix)
    ++ (callPackage ./windows.nix)
    ++ (callPackage ./quickfix.nix)

    ++ (with pkgs.vimPlugins; [
    {
      plugin = camouflage-nvim;
      optional = true;
      type = "lua";
      config = /*lua*/''
        lze.load {
          "${camouflage-nvim.pname}",
          event = vim.g.pre_load_events,
          keys = {
            { '<leader>ct', '<cmd>CamouflageToggle<cr>', desc = 'Toggle Camouflage' },
            { '<leader>cr', '<cmd>CamouflageReveal<cr>', desc = 'Reveal Line' },
            { '<leader>cy', '<cmd>CamouflageYank<cr>', desc = 'Yank Value' },
            { '<leader>cf', '<cmd>CamouflageFollowCursor<cr>', desc = 'Follow Cursor' },
          },
          after = function()
            require('camouflage').setup({
              pwned = {
                enabled = false,
                auto_check = true,            -- Check on BufEnter
                check_on_save = true,         -- Check on BufWritePost
                check_on_change = false,       -- Check on TextChanged with debounce
                show_sign = false,             -- Show sign column indicator
                show_virtual_text = true,     -- Show virtual text with breach count
                show_line_highlight = true,   -- Highlight the line
                sign_text = '!',
                sign_hl = 'DiagnosticWarn',
                virtual_text_format = 'PWNED (%s)',
                virtual_text_hl = 'DiagnosticWarn',
                line_hl = 'CamouflagePwned',
              },
              project_config = {
                enabled = false,
              }
            })

            require('camouflage').on('variable_detected', function(bufnr, var)
              local sensitive_patterns = { 'PASS', 'TOKEN', 'PRIVATE', 'URL', "DSN", "ACCESS_KEY", "SECRET", "API_KEY" }
              for _, pattern in ipairs(sensitive_patterns) do
                if var.key:upper():match(pattern) then
                  return true
                end
              end
              return false
            end)
          end
        }
      '';
    }
    {
      plugin = bionic-reading-nvim;
      optional = true;
      type = "lua";
      config = /*lua*/''
        lze.load {
          "${bionic-reading-nvim.pname}",
          after = function()
            require('bionic-reading').setup({
              auto_highlight = true,
              file_types = {
                ["text"] = "any",
                ["markdown"] = "any",
                ["lua"] = {
                  "comment",
                },
                ["nix"] = {
                  "comment",
                },
                ["golang"] = {
                  "comment",
                },
                ["python"] = {
                  "comment",
                },
              },
              hl_group_value = {
                bold = true,
              },
              prompt_user = true,
              treesitter = true,
              update_in_insert_mode = true,
            })
          end
        }
      '';
    }

    {
      plugin = plenary-nvim;
      optional = true;
      type = "lua";
      config = /*lua*/''
        lze.load {
          "${plenary-nvim.pname}",
          on_require = {"plenary.job", "plenary.path", "plenary.functional", "plenary.compat"},
        }
      '';
    }
    smart-splits-nvim
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


  ai = (callPackage ./ai);

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
    ++ ai.plugins
    ++ (callPackage ./autocomplete.nix)
    ++ (callPackage ./blink-pairs.nix)
    ++ (callPackage ./kube.nix)
    ++ (callPackage ./ui.nix)
    ++ langs.plugins
    ++ (
    with pkgs.vimPlugins; [
      {
        plugin = snacks-nvim;
        type = "lua";
        optional = true;
        config = /*lua*/''
          lze.load {
            "${snacks-nvim.pname}",
          on_require = {"snacks", "snacks.picker"},
          }
        '';
      }

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

  all-packages = langs.packages ++ small-packages ++ ai.packages;

  nvim-treesitter = inputs.nvim-treesitter-main.packages.${prev.system}.nvim-treesitter;
  nvim-treesitter-textobjects = inputs.nvim-treesitter-main.packages.${prev.system}.nvim-treesitter-textobjects;
in
rec
{
  opencode = inputs.opencode.packages.${prev.system}.opencode;
  vectorcode = prev.vectorcode.overrideAttrs {
    meta.license = "MIT";
    meta.platforms = prev.vectorcode.meta.platforms ++ [ "aarch64-unknown-linux-gnu" ];
  };


  tree-sitter-kulala-http = prev.tree-sitter.buildGrammar
    {
      passthru.name = "kulala_http";
      language = "kulala_http";
      version = inputs.kulala-nvim.lastModifiedDate;
      src = inputs.kulala-nvim;
      location = "lua/tree-sitter";
    };
  kulala-fmt = inputs.kulala-fmt.packages.${prev.system}.default;

  smart-splits-nvim-src = inputs.smart-splits-nvim;

  vimPlugins = prev.vimPlugins.extend
    (
      f: p: {
        nvim-treesitter = (nvim-treesitter.withPlugins (_: [ tree-sitter-kulala-http ] ++ nvim-treesitter.allGrammars)).overrideAttrs (old: {
          postInstall = old.postInstall + ''
            ln -sfT ${tree-sitter-kulala-http}/queries/kulala_http $out/queries/kulala_http
          '';
        });

        nvim-treesitter-textobjects = nvim-treesitter-textobjects.overrideAttrs {
          dependencies = [ f.nvim-treesitter ];
        };

        hlargs-nvim = (mkNvimPlugin inputs.hlargs-nvim "hlargs.nvim").overrideAttrs
          {
            dependencies = [ f.nvim-treesitter ];
          };

        nvim-treesitter-context = p.nvim-treesitter-context.overrideAttrs
          {
            dependencies = [ f.nvim-treesitter ];
          };

        kulala-nvim = p.kulala-nvim.overrideAttrs {
          version = inputs.kulala-nvim.lastModifiedDate;
          src = inputs.kulala-nvim;
          dependencies = [ f.nvim-treesitter ];
        };


        cmp-diag-codes = (mkNvimPlugin inputs.cmp-diag-codes "cmp-diag-codes");

        yaml-nvim = (mkNvimPlugin inputs.yaml-nvim "yaml.nvim");
        gentags = (mkNvimPlugin inputs.gentags-lua "gentags.lua").overrideAttrs
          {
            dependencies = [ prev.vimPlugins.plenary-nvim ];
          };

        namu-nvim = (mkNvimPlugin inputs.namu-nvim "namu.nvim");

        stayinpalce = (mkNvimPlugin inputs.stay-in-place-nvim "stay-in-place.nvim");

        smart-splits-nvim = (mkNvimPluginNoCheck inputs.smart-splits-nvim "smart-splits.nvim");

        local-highlight-nvim = (mkNvimPlugin inputs.local-highlight-nvim "local-highlight.nvim");
        whatthejump-nvim = (mkNvimPlugin inputs.whatthejump-nvim "whatthejump.nvim");

        nvim-window = (mkNvimPlugin inputs.nvim-window "nvim-window");

        django-nvim = (mkNvimPlugin inputs.django-nvim "django-nvim");

        opencode-nvim = (mkNvimPlugin inputs.opencode-nvim "opencode-nvim").overrideAttrs {
          dependencies = [
            prev.vimPlugins.render-markdown-nvim
            prev.vimPlugins.blink-cmp
            prev.vimPlugins.fzf-lua
            prev.vimPlugins.plenary-nvim

            opencode
          ];
        };

        nvim-aider = (mkNvimPluginNoCheck inputs.nvim-aider "nvim-aider").overrideAttrs {
          dependencies = [
            prev.vimPlugins.snacks-nvim
          ];
        };

        camouflage-nvim = (mkNvimPlugin inputs.camouflage-nvim "camouflage-nvim");
        bionic-reading-nvim = (mkNvimPlugin inputs.bionic-reading-nvim "bionic-reading-nvim");
      }
    );

  coding-packages = pkgs.buildEnv {
    name = "coding-packages";
    paths = all-packages;
    pathsToLink = [ "/bin" "/share" ];
  };
  minimal-coding-packages = pkgs.buildEnv {
    name = "minimal-coding-packages";
    paths = minimal-packages;
    pathsToLink = [ "/bin" "/share" ];
  };
  small-coding-packages = pkgs.buildEnv {
    name = "small-coding-packages";
    paths = small-packages;
    pathsToLink = [ "/bin" "/share" ];
  };

  # This is the neovim derivation
  # returned by the overlay
  nvim-pkg = mkNeovim {
    plugins = all-plugins;
    pkg = neovim-nightly;
    extraPackages = all-packages;
    ignoreConfigRegexes = [
      "^snippets/.*"
    ];
  };

  nvim-small = mkNeovim {
    plugins = smallset-plugins;
    pkg = final.pkgs.neovim-unwrapped;
    ignoreConfigRegexes = [
      "^lsp/.*.lua"
    ];
    extraPackages = small-packages;
  };

  nvim-minimal = mkNeovim {
    plugins = minimal-plugins;
    pkg = final.pkgs.neovim-unwrapped;
    ignoreConfigRegexes = [
      "^lsp/.*.lua"
    ];
    extraPackages = minimal-packages;
  };

  # This is meant to be used within a devshell.
  # Instead of loading the lua Neovim configuration from
  # the Nix store, it is loaded from $XDG_CONFIG_HOME/nvim-dev
  nvim-dev = mkNeovim {
    plugins = all-plugins;
    pkg = neovim-nightly;
    appName = "nvim-dev";
    wrapRc = true;
    extraPackages = all-packages;
    ignoreConfigRegexes = [
      "^snippets/.*"
    ];
  };

  nvim-dev-small = mkNeovim {
    plugins = smallset-plugins;
    pkg = final.pkgs.neovim-unwrapped;
    appName = "nvim-dev-small";
    wrapRc = true;
    ignoreConfigRegexes = [
      "^lsp/.*.lua"
    ];
    extraPackages = small-packages;
  };

  nvim-dev-minimal = mkNeovim {
    plugins = minimal-plugins;
    pkg = final.pkgs.neovim-unwrapped;
    appName = "nvim-dev-minimal";
    wrapRc = true;
    ignoreConfigRegexes = [
      "^lsp/.*.lua"
    ];
    extraPackages = minimal-packages;
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
