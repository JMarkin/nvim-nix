{ inputs, mkNvimPlugin, pkgs, ... }:
let

  yaml-nvim = (mkNvimPlugin inputs.yaml-nvim "yaml.nvim");
  gentags = (mkNvimPlugin inputs.gentags-lua "gentags.lua").overrideAttrs
    {
      dependencies = [ pkgs.vimPlugins.plenary-nvim ];
    };
in
{
  packages = with pkgs; [
    bash-language-server
    yaml-language-server
    # systemd-language-server
    # nginx-language-server
    docker-language-server

    vacuum-go
    taplo

    universal-ctags
  ];

  plugins = with pkgs.vimPlugins; [
    {
      plugin = nvim-lint;
      type = "lua";
      optional = true;
      config = /*lua*/''
        lze.load {
          "${nvim-lint.pname}",
          on_require = "lint",
          after = function()
            require("lint").linters_by_ft = vim.g.linter_by_ft
            require("lint").linters.sqlfluff.args = {
              "lint",
              "--format=json",
              "--dialect=postgres",
            }
          end
        }
      '';
    }
    {
      plugin = conform-nvim;
      type = "lua";
      optional = true;
      config = /*lua*/''
        lze.load {
          "${conform-nvim.pname}",
          cmd = { "ConformInfo" },
          on_require = "conform",
          after = function()
            require("conform").setup({
              formatters_by_ft = vim.g.formatters_by_ft,
              default_format_opts = {
                lsp_format = "fallback",
              },
              -- Customize formatters
              formatters = {
                sqlfluff = {
                  prepend_args = { "--dialect", "postgres" },
                },
              },
            })
          end
        }
      '';
    }

    {
      plugin = SchemaStore-nvim;
      type = "lua";
      optional = false;
      config = /*lua*/''
        lze.load {
          "${SchemaStore-nvim.pname}",
          on_require = "schemastore",
        }
      '';
    }
    {
      plugin = yaml-nvim;
      type = "lua";
      optional = true;
      config = /*lua*/''
        lze.load {
          "${yaml-nvim.pname}",
          on_require = "yaml",
          ft = {"yaml"}
        }
      '';
    }

    (mkNvimPlugin inputs.namu-nvim "namu.nvim")

    gentags

  ];
}

