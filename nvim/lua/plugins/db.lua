local is_not_mini = require("funcs").is_not_mini
local autocmd = vim.api.nvim_create_autocmd

return {
  {
    "tpope/vim-dadbod",
    -- from nix
    dev = true,
    lazy = true,
    ft = { "sql", "mssql", "plsql" },
  },
  {
    "kristijanhusak/vim-dadbod-completion",
    -- from nix
    dev = true,
    lazy = true,
    ft = { "sql", "mssql", "plsql" },
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    -- from nix
    dev = true,
    cond = is_not_mini,
    dependencies = {
      "tpope/vim-dadbod",
      "kristijanhusak/vim-dadbod-completion",
    },
    init = function(event)
      vim.g.db_ui_execute_on_save = 0
      vim.g.db_ui_win_position = "right"
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_env_variable_url = "DATABASE_URL"
      vim.g.db_ui_use_nvim_notify = true
      vim.g.db_ui_auto_execute_table_helpers = 1

      autocmd("FileType", {
        pattern = { "dbui" },
        callback = function()
          vim.keymap.set("n", "<tab>", "<Plug>(DBUI_SelectLine)", { buffer = event.buffer, silent = true })
        end,
      })
    end,
    cmd = { "DBUI", "DBUIToggle" },
  },
}
