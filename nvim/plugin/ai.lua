if vim.g.did_load_ai_plugin then
  return
end
vim.g.did_load_ai_plugin = true

local g = vim.g

-- ollama setup
g.ollama_host = vim.env.OLLAMA_HOST or "localhost"
g.ollama_port = vim.env.OLLAMA_PORT or "11434"
g.ollama_url = string.format("http://%s:%s", g.ollama_host, g.ollama_port)
g.ollama_generate_endpoint = string.format("%s/api/generate", g.ollama_url)
g.ollama_chat_endpoint = string.format("%s/api/chat", g.ollama_url)
g.ollama_completions_endpoint = string.format("%s/api/generate", g.ollama_url)
g.ollama_model = "hf.co/mradermacher/Qwen2.5-CoderX-14B-v0.5-GGUF:Q8_0"

local ollama_modify_config = function(cfg)
  cfg.provider = "ollama"
  cfg.providers.ollama = {
    endpoint = g.ollama_url,
    model = g.ollama_model,
    disabled_tools = { "python" },
    extra_request_body = {
      -- num_ctx = 1024 * 20,
      temperature = 0.5,
    },
  }
  cfg.rag_service.llm = {
    provider = "ollama",
    endpoint = g.ollama_url,
    api_key = "",
    model = g.ollama_model,
    extra = nil,
  }
  cfg.rag_service.embed = {
    provider = "ollama",
    endpoint = g.ollama_url,
    api_key = "",
    model = "nomic-embed-text:latest",
    extra = {
      embed_batch_size = 10,
    },
  }
  require("avante").setup(cfg)
end

-- airun setup
g.airun_url = vim.env.AI_RUN_URL
g.airun_endpoint = string.format("%s/v1", g.airun_url)
g.airun_chat_endpoint = string.format("%s/v1/chat", g.airun_url)
g.airun_model = vim.env.AI_RUN_MODEL
g.airun_autocomplete_model = vim.env.AI_RUN_AUOTOCOMPLETE_MODEL
g.airun_embedded_model = vim.env.AI_RUN_EMBEDDED_MODEL

local airun_modify_config = function(cfg)
  cfg.provider = "airun"
  cfg.mode = "legacy"
  cfg.auto_suggestions_provider = "airun_autocomplete"
  cfg.providers.airun = {
    __inherited_from = "openai",
    endpoint = g.airun_endpoint,
    api_key_name = "AI_RUN_TOKEN",
    model = g.airun_model,
    disable_tools = true,
    allow_insecure = true,
    extra = {
      temperature = 0.7,
      max_tokens = 512,
    },
  }
  cfg.providers.airun_autocomplete = {
    __inherited_from = "openai",
    endpoint = g.airun_endpoint,
    allow_insecure = true,
    api_key_name = "AI_RUN_TOKEN",
    model = g.airun_autocomplete_model,
    disable_tools = true,
  }
  cfg.rag_service.enabled = false
  cfg.rag_service.llm = {
    provider = "airun",
    endpoint = g.airun_endpoint,
    allow_insecure = true,
    api_key = "AI_RUN_TOKEN",
    model = g.airun_model,
    extra = {
      temperature = 0.7,
      max_tokens = 512,
    },
  }
  cfg.rag_service.embed = {
    provider = "airun",
    endpoint = g.airun_endpoint,
    allow_insecure = true,
    api_key = "AI_RUN_TOKEN",
    model = g.ai_run_embedded_model,
    extra = {
      embed_batch_size = 16,
    },
  }

  require("avante").setup(cfg)
end

lze.load({
  "avante.nvim",
  event = vim.g.post_load_events,
  on_require = { "avante", "avante_lib", "avante.api" },
  after = function()
    local opts = {
      mode = "agentic",
      debug = false,
      providers = {},
      web_search_engine = {},
      behaviour = {
        auto_set_keymaps = true,
        auto_set_highlight_group = true,

        auto_focus_sidebar = true,

        auto_suggestions = false,
        auto_suggestions_respect_ignore = true,
        auto_apply_diff_after_generation = false,
        jump_result_buffer_on_finish = false,
        support_paste_from_clipboard = true,
        minimize_diff = true,
        enable_token_counting = true,
        use_cwd_as_project_root = true,
        auto_focus_on_diff_view = true,
      },
      hints = { enabled = true },

      rag_service = { -- RAG Service configuration
        enabled = false,
        host_mount = os.getenv("HOME"),
        runner = "nix", -- Runner for the RAG service (can use docker or nix)
        docker_extra_args = "",
      },

      mappings = {
        suggestion = {
          accept = "<Tab>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
        diff = {
          ours = "gH",
          theirs = "gh",
          all_theirs = "gA",
          both = "gB",
          cursor = "gc",
          next = "]x",
          prev = "[x",
        },
        jump = {
          next = "]]",
          prev = "[[",
        },
        submit = {
          normal = "<CR>",
          insert = "<C-s>",
        },
        cancel = {
          normal = { "<C-c>", "<Esc>", "q" },
          insert = { "<C-c>" },
        },
        ask = "<leader>aa",
        new_ask = "<leader>an",
        zen_mode = "<leader>az",
        edit = "<leader>ae",
        refresh = "<leader>ar",
        focus = "<leader>af",
        stop = "<leader>aS",
        toggle = {
          default = "<leader>at",
          debug = "<leader>ad",
          selection = "<leader>aC",
          suggestion = "<leader>as",
          repomap = "<leader>aR",
        },
        sidebar = {
          expand_tool_use = "<S-Tab>",
          next_prompt = "<up>",
          prev_prompt = "<down>",
          apply_all = "A",
          apply_cursor = "a",
          retry_user_request = "r",
          edit_user_request = "e",
          switch_windows = "<c-n>",
          toggle_code_window = "x",
          remove_file = "d",
          add_file = "@",
          close = { "q" },
          ---@alias AvanteCloseFromInput { normal: string | nil, insert: string | nil }
          ---@type AvanteCloseFromInput | nil
          close_from_input = nil, -- e.g., { normal = "<Esc>", insert = "<C-d>" }
          ---@alias AvanteToggleCodeWindowFromInput { normal: string | nil, insert: string | nil }
          ---@type AvanteToggleCodeWindowFromInput | nil
          toggle_code_window_from_input = nil, -- e.g., { normal = "x", insert = "<C-;>" }
        },
        files = {
          add_current = "<leader>ac", -- Add current buffer to selected files
          add_all_buffers = "<leader>aB", -- Add all buffer files to selected files
        },
        select_model = "<leader>a?", -- Select model command
        select_history = "<leader>ah", -- Select history command
        confirm = {
          focus_window = "<C-w>f",
          code = "c",
          resp = "r",
          input = "i",
        },
      },

      repo_map = {
        ignore_patterns = {
          "%.git",
          "%.worktree",
          "__pycache__",
          "node_modules",
          "target",
          "build",
          "dist",
          "BUILD",
          "vendor%.",
          "%.min%.",
          ".devenv%.",
          ".direnv%.",
        }, -- ignore files matching these
        negate_patterns = {}, -- negate ignore files matching these.
      },

      selector = {
        provider = "fzf_lua",
      },
    }

    require("avante_lib").load()
    airun_modify_config(opts)
  end,
})
