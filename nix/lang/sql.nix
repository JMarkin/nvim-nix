{ pkgs, ... }:
{

  packages = with pkgs; [
    sqruff
    postgresql
  ];

  luasetup = /*lua*/''
    vim.lsp.enable("sqruff", vim.g.lsp_autostart)
  '';

  plugins = with pkgs.vimPlugins;[
    {
      plugin = vim-dadbod;
      optional = true;
      config = /*lua*/''
        lze.load {
          "${vim-dadbod.pname}",
          on_plugin = "vim-dadbod-ui",
          ft= { "sql", "mssql", "plsql" }
        }
      '';
    }
    {
      plugin = vim-dadbod-completion;
      optional = true;
      config = /*lua*/''
        lze.load {
          "${vim-dadbod-completion.pname}",
          on_plugin = "vim-dadbod-ui",
          ft= { "sql", "mssql", "plsql" }
        }
      '';
    }
    {
      plugin = vim-dadbod-ui;
      optional = true;
      config = /*lua*/''
        lze.load {
          "${vim-dadbod-ui.pname}",
          cmd = { "DBUI", "DBUIToggle" },
          before = function(event)
            vim.g.db_ui_execute_on_save = 0
            vim.g.db_ui_win_position = "right"
            vim.g.db_ui_show_database_icon = 1
            vim.g.db_ui_use_nerd_fonts = 1
            vim.g.db_ui_env_variable_url = "DATABASE_URL"
            vim.g.db_ui_use_nvim_notify = true
            vim.g.db_ui_auto_execute_table_helpers = 1

            vim.api.nvim_create_autocmd("FileType", {
              pattern = { "dbui" },
              callback = function()
                vim.keymap.set("n", "<tab>", "<Plug>(DBUI_SelectLine)", { buffer = event.buffer, silent = true })
              end,
            })
          end,
        }
      '';
    }

  ];

}
