if vim.g.did_load_avante_plugin or vim.g.did_load_ai_plugin then
  return
end
vim.g.did_load_avante_plugin = true

local g = vim.g

local opts = {
  mode = "agentic",
  rules = {
    project_dir = ".avante/rules", -- relative to project root, can also be an absolute path
    global_dir = "~/.config/avante/rules", -- absolute path
  },
  -- debug = true,
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
    auto_approve_tool_permissions = false,
    auto_add_current_file = false,
    confirmation_ui_style = "popup",
  },

  selection = {
    enabled = false,
    hint_display = "delayed",
  },
  provider = "ollama",
  providers = {
    ollama = {
      endpoint = g.ollama_url,
      model = "danielsheep/gpt-oss-20b-Unsloth:latest",
      extra = {
        num_ctx = 131072,
      },
    },
    airun = {
      __inherited_from = "openai",
      endpoint = g.airun_endpoint,
      api_key_name = "AI_RUN_TOKEN",
      model = g.airun_model,
      allow_insecure = true,
      extra = {
        temperature = 0.7,
        max_tokens = 512,
      },
    },
    airun_autocomplete = {
      __inherited_from = "openai",
      endpoint = g.airun_endpoint,
      allow_insecure = true,
      api_key_name = "AI_RUN_TOKEN",
      model = g.airun_autocomplete_model,
    },
  },
  rag_service = { -- RAG Service configuration
    enabled = false,
    host_mount = os.getenv("HOME"),
    runner = "nix", -- Runner for the RAG service (can use docker or nix)
    docker_extra_args = "",
    llm = {
      provider = "ollama",
      endpoint = g.ollama_url,
      api_key = "",
      model = "orieg/gemma3-tools:4b",
      extra = {
        num_ctx = 131072,
      },
    },
    embed = {
      provider = "ollama",
      endpoint = g.ollama_url,
      api_key = "",
      model = "embeddinggemma:latest",
      extra = {
        embed_batch_size = 10,
      },
    },
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
      switch_windows = "<Tab>",
      reverse_switch_windows = "<S-Tab>",
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
  windows = {
    ---@alias AvantePosition "right" | "left" | "top" | "bottom" | "smart"
    ---@type AvantePosition
    position = "smart",
    sidebar_header = {
      enabled = true, -- true, false to enable/disable the header
      align = "left", -- left, center, right for title
      rounded = true,
    },
    edit = {
      start_insert = false, -- Start insert mode when opening the edit window
    },
    ask = {
      floating = false,
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

vim.api.nvim_create_user_command("AvanteAIRun", function(_)
  opts.provider = "airun"
  opts.auto_suggestions_provider = "airun_autocomplete"

  require("avante").setup(opts)
end, {})

lze.load({
  "avante.nvim",
  event = vim.g.post_load_events,
  on_require = { "avante", "avante_lib", "avante.api" },
  after = function()
    require("avante_lib").load()
    require("avante").setup(opts)
  end,
})
