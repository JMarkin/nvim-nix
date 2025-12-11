if vim.g.did_load_http_plugin then
  return
end
vim.g.did_load_http_plugin = true

lze.load({
  "kulala.nvim",
  ft = { "http", "rest" },
  after = function()
    require("kulala").setup({
      ui = {
        default_winbar_panes = {
          "headers_body",
          "verbose",
          "script_output",
          "stats",
          "report",
        },
      },
      contenttypes = {
        ["application/json"] = {
          ft = "json",
          formatter = vim.fn.executable("jaq") == 1 and { "jaq", "." },
          pathresolver = function(...)
            return require("kulala.parser.jsonpath").parse(...)
          end,
        },
        ["application/graphql-response+json"] = "application/json",
        ["application/graphql"] = {
          ft = "graphql",
          formatter = vim.fn.executable("prettier") == 1
            and { "prettier", "--stdin-filepath", "graphql", "--parser", "graphql" },
          pathresolver = nil,
        },
        ["application/xml"] = {
          ft = "xml",
          formatter = vim.fn.executable("xmllint") == 1 and { "xmllint", "--format", "-" },
          pathresolver = vim.fn.executable("xmllint") == 1 and { "xmllint", "--xpath", "{{path}}", "-" },
        },
        ["text/html"] = {
          ft = "html",
          formatter = vim.fn.executable("xmllint") == 1 and { "xmllint", "--format", "--html", "-" },
          pathresolver = nil,
        },
      },

-- stylua: ignore start
      global_keymaps = {
          ["Open scratchpad"] = { "<leader>hb", function() require("kulala").scratchpad() end, },
          ["Open kulala"] = { "<leader>ho", function() require("kulala").open() end, },

          ["Show headers/body"] = { "<leader>ht", function() require("kulala.ui").show_headers_body() end, ft = { "http", "rest" }, },
          ["Show stats"] = { "<leader>hS", function() require("kulala").show_stats() end, ft = { "http", "rest" }, },

          ["Close window"] = { "q", function() require("kulala").close() end, ft = { "http", "rest" }, },

          ["Copy as cURL"] = { "<leader>hc", function() require("kulala").copy() end, ft = { "http", "rest" }, },
          ["Paste from curl"] = { "<leader>hC", function() require("kulala").from_curl() end, ft = { "http", "rest" }, },

          ["Send request"] = { "<leader>hs", function() require("kulala").run() end, mode = { "n", "v" }, },
          ["Send request <cr>"] = { "<CR>", function() require("kulala").run() end, mode = { "n", "v" }, ft = { "http", "rest" }, },
          ["Send all requests"] = { "<leader>ha", function() require("kulala").run_all() end, mode = { "n", "v" }, },

          ["Inspect current request"] = { "<leader>hi", function() require("kulala").inspect() end, ft = { "http", "rest" } },
          ["Open cookies jar"] = { "<leader>hj", function() require("kulala").open_cookies_jar() end, ft = { "http", "rest" } },
          ["Replay the last request"] = { "<leader>hr", function() require("kulala").replay() end, },

          ["Find request"] = { "<leader>hf", function() require("kulala").search() end, ft = { "http", "rest" }, },
          ["Jump to next request"] = { "]h", function() require("kulala").jump_next() end, ft = { "http", "rest" }, },
          ["Jump to previous request"] = { "[h", function() require("kulala").jump_prev() end, ft = { "http", "rest" }, },

          ["Select environment"] = { "<leader>he", function() require("kulala").set_selected_env() end, ft = { "http", "rest" }, },
          ["Manage Auth Config"] = { "<leader>hu", function() require("lua.kulala.ui.auth_manager").open_auth_config() end, ft = { "http", "rest" }, },
          ["Download GraphQL schema"] = { "<leader>hg", function() require("kulala").download_graphql_schema() end, ft = { "http", "rest" }, },

          ["Clear globals"] = { "<leader>hx", function() require("kulala").scripts_clear_global() end, ft = { "http", "rest" }},
          ["Clear cached files"] = { "<leader>hX", function() require("kulala").clear_cached_files() end, ft = { "http", "rest" }, },
      },

      kulala_keymaps = {
        ["Show headers and body"] = { "A", function() require("kulala.ui").show_headers_body() end, },
        ["Show verbose"] = { "V", function() require("kulala.ui").show_verbose() end, },

        ["Show script output"] = { "O", function() require("kulala.ui").show_script_output() end, },
        ["Show stats"] = { "S", function() require("kulala.ui").show_stats() end, },
        ["Show report"] = { "R", function() require("kulala.ui").show_report() end, },
        ["Show filter"] = { "F", function() require("kulala.ui").toggle_filter() end },

        ["Send WS message"] = { "<S-CR>", function() require("kulala.cmd.websocket").send() end, mode = { "n", "v" }, },
        ["Interrupt requests"] = { "<C-c>", function() require("kulala.cmd.websocket").close() end, desc = "also: CLose WS connection" },

        ["Next response"] = { "]", function() require("kulala.ui").show_next() end, },
        ["Previous response"] = { "[", function() require("kulala.ui").show_previous() end, },
        ["Jump to response"] = { "<CR>", function() require("kulala.ui").jump_to_response() end, desc = "also: Send WS message for WS connections" },

        ["Clear responses history"] = { "X", function() require("kulala.ui").clear_responses_history() end, },

        ["Show help"] = { "?", function() require("kulala.ui").show_help() end, },
        ["Show news"] = { "g?", function() require("kulala.ui").show_news() end, },

        ["Toggle split/float"] = { "|", function() require("kulala.ui").toggle_display_mode() end, prefix = false, },
        ["Close"] = { "q", function() require("kulala.ui").close_kulala_buffer() end, },
      },
      -- stylua: ignore end
    })
  end,
})
