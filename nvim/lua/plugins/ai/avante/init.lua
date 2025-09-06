return {
  "yetone/avante.nvim",
  event = vim.g.post_load_events,
  -- from nix
  dev = true,
  opts = {
    mode = "agentic",
    debug = false,
    providers = {},
    web_search_engine = {},
    behaviour = {
      auto_focus_sidebar = true,
      auto_suggestions = false,
      auto_suggestions_respect_ignore = false,
      auto_set_highlight_group = true,
      auto_set_keymaps = true,
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
        "ventor%.",
        "%.min%.",
        ".devenv",
      }, -- ignore files matching these
      negate_patterns = {}, -- negate ignore files matching these.
    },

    selector = {
      provider = "fzf_lua",
    },
  },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    {
      -- from nix
      dev = true,
      "Kaiser-Yang/blink-cmp-avante",
    },

    "ibhagwan/fzf-lua", -- for file_selector provider fzf
  },

  config = function(_, opts)
    require("avante_lib").load()
    opts = require("plugins.ai.avante.airun").modify_config(opts)
    -- opts = require("plugins.ai.avante.ollama").modify_config(opts)

    require("avante").setup(opts)
  end,
}
