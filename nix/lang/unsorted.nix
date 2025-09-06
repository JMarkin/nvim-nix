{ inputs, mkNvimPlugin, pkgs, ... }:
let

  yaml-nvim = (mkNvimPlugin inputs.yaml-nvim "yaml.nvim");
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

    vscode-langservers-extracted

    biome

  ];

  plugins = with pkgs.vimPlugins; [
    {
      plugin = nvim-lint;
      type = "lua";
      optional = true;
      config = /*lua*/''
        require("lze").load {
          "nvim-lint",
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
        require("lze").load {
          "conform.nvim",
          cmd = { "ConformInfo" },
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
      optional = true;
      config = /*lua*/''
        require("lze").load {
          "schemastore.nvim",
        }
      '';
    }
    {
      plugin = yaml-nvim;
      type = "lua";
      optional = true;
      config = /*lua*/''
        require("lze").load {
          "yaml.nvim",
          ft = {"yaml"}
        }
      '';
    }


  ];
}

