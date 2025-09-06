local adapters = require("plugins.ai.codecompanion.adapters")

return {
  "olimorris/codecompanion.nvim",
  -- from nix
  dev = true,
  cmd = {
    "CodeCompanionChat",
    "CodeCompanion",
    "CodeCompanionCmd",
    "CodeCompanionActions",
    "CodeCompanionHistory",
  },
  keys = {
    {
      "<leader>cc",
      function()
        require("codecompanion").toggle()
      end,
      desc = "Code Companion",
      silent = true,
    },
    {
      "<leader>cc",
      ":'<,'>CodeCompanionChat Add<cr>",
      desc = "Code Companion Add",
      silent = true,
      mode = "x",
      noremap = true,
    },
    {
      "<C-?>",
      function()
        require("codecompanion").toggle()
      end,
      desc = "Code Companion",
      silent = true,
    },
    {
      "<C-?>",
      ":'<,'>CodeCompanionChat Add<cr>",
      desc = "Code Companion Add",
      silent = true,
      mode = "x",
      noremap = true,
    },
    {
      "<leader>ci",
      ":CodeCompanion<cr>",
      desc = "Code Companion inline",
      silent = true,
      mode = "n",
      noremap = true,
    },
    {
      "<leader>ci",
      ":'<,'>CodeCompanion<cr>",
      desc = "Code Companion inline",
      silent = true,
      mode = "x",
      noremap = true,
    },
    {
      "<leader>ca",
      ":'<,'>CodeCompanionActions<cr>",
      desc = "Code Companion Actions",
      silent = true,
      mode = "x",
      noremap = true,
    },
    {
      "<leader>ca",
      ":CodeCompanionActions<cr>",
      desc = "Code Companion Actions",
      silent = true,
      mode = "n",
      noremap = true,
    },
    {
      "<leader>ch",
      ":CodeCompanionHistory<cr>",
      desc = "Code Companion Actions",
      silent = true,
      mode = "n",
      noremap = true,
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "j-hui/fidget.nvim",
    {
      "ravitemer/codecompanion-history.nvim",
      -- from nix
      dev = true,
    },
    {
      "Davidyz/VectorCode",
      -- lazy = true,
      -- from nix
      dev = true,
      dependencies = { "nvim-lua/plenary.nvim" },
      opts = {
        async_opts = {
          notify = true,
        },
      },
      init = function()
        vim.api.nvim_create_autocmd("LspAttach", {
          callback = function()
            local bufnr = vim.api.nvim_get_current_buf()
            local cacher = require("vectorcode.config").get_cacher_backend()
            require("vectorcode.cacher").utils.async_check("config", function()
              cacher.register_buffer(bufnr, {
                n_query = 10,
              })
            end, nil)
          end,
          desc = "Register buffer for VectorCode",
        })
      end,
      config = function(_, opts)
        require("vectorcode").setup(opts)
      end,
    },
  },
  init = function()
    require("plugins.ai.codecompanion.fidget-spinner"):init()
  end,
  config = function()
    local opts = {
      adapters = adapters,
      strategies = {
        chat = {
          adapter = "default_adapter",
          keymaps = require("plugins.ai.codecompanion.keymaps"),
        },
        inline = {
          adapter = "default_adapter",
          keymaps = {
            accept_change = {
              modes = { n = "gh" },
              description = "Accept the suggested change",
            },
            reject_change = {
              modes = { n = "gH" },
              description = "Reject the suggested change",
            },
          },
        },
        agent = { adapter = "default_adapter" },
      },
      display = {
        chat = {
          -- window = {
          --     layout = "float",
          -- },
          icons = {
            pinned_buffer = "📌 ",
            watched_buffer = "👀 ",
          },
          show_header_separator = true,
          show_settings = true,
        },
      },
      opts = {
        -- system_prompt = require("plugins.ai.codecompanion.system_prompt"),
      },
      prompt_library = require("plugins.ai.codecompanion.prompts"),
      extensions = {
        history = {
          enabled = true,
          opts = {
            keymap = "<leader>sh",
            save_chat_keymap = "sc",
            auto_save = true,
            expiration_days = 0,
            picker = "fzf-lua",
            auto_generate_title = false,
            ---On exiting and entering neovim, loads the last chat on opening chat
            continue_last_chat = false,
            ---When chat is cleared with `gx` delete the chat from history
            delete_on_clearing_chat = true,
            ---Directory path to save the chats
            dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
            ---Enable detailed logging for history extension
            enable_logging = false,
          },
        },
      },
    }

    local ok, _ = pcall(require, "mchup")
    if ok then
      opts.extensions.mcphub = {
        callback = "mcphub.extensions.codecompanion",
        opts = {
          make_vars = true,
          make_slash_commands = true,
          show_result_in_chat = true,
        },
      }
    end

    ok, _ = pcall(require, "vectorcode")
    if ok then
      opts.extensions.vectorcode = {
        opts = {
          tool_group = {
            enabled = true,
            extras = {},
            collapse = false,
          },
          tool_opts = {
            ls = {},
            vectorise = {},
            query = {
              max_num = { chunk = -1, document = -1 },
              default_num = { chunk = 50, document = 10 },
              include_stderr = false,
              use_lsp = true,
              no_duplicate = true,
              chunk_mode = false,
            },
          },
        },
      }
    end

    require("codecompanion").setup(opts)
  end,
}
