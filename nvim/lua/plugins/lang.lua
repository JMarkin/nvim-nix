local fn = require("funcs")
local is_not_mini = require("funcs").is_not_mini

return {
  {
    "mfussenegger/nvim-lint",
    lazy = true,
    enabled = true,
    config = function()
      require("lint").linters_by_ft = vim.g.linter_by_ft
      require("lint").linters.sqlfluff.args = {
        "lint",
        "--format=json",
        "--dialect=postgres",
      }
    end,
  },
  {
    "stevearc/conform.nvim",
    cmd = { "ConformInfo" },
    config = function()
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
    end,
  },
  {
    "folke/lazydev.nvim",
    ft = "lua",
    -- from nix
    dev = true,
  },
  {
    "mrcjkb/rustaceanvim",
    cond = is_not_mini,
    lazy = false,
    ft = { "rust" },
    -- from nix
    dev = true,
  },
  {
    name = "clangd_extenstions",
    url = "https://git.sr.ht/~p00f/clangd_extensions.nvim",
    cond = is_not_mini,
    lazy = true,
  },
  {
    url = "ray-x/go.nvim",
    -- from nix
    dev = true,
    cond = is_not_mini,
    opts = {
      lsp_cfg = false,
      diagnostic = false,
      luasnip = false,
      lsp_inlay_hints = {
        enable = false,
      },
    },
    config = function(_, opts)
      require("go").setup(opts)
    end,
    event = { "CmdlineEnter" },
    ft = { "go", "gomod" },
  },
  { "b0o/schemastore.nvim", cond = is_not_mini, lazy = true },
  {
    "ranelpadon/python-copy-reference.vim",
    cond = is_not_mini,
    ft = { "python" },
    init = function()
      vim.g.python_remove_prefixes = { "src" }
    end,
    keys = {
      {
        "<leader>lcd",
        ":PythonCopyReferenceDotted<CR>",
        desc = "Copy as: Python Dotted",
      },
      {
        "<leader>lcp",
        ":PythonCopyReferencePytest<CR>",
        desc = "Copy as: Pytest",
      },
      {
        "<leader>lci",
        ":PythonCopyReferenceImport<CR>",
        desc = "Copy as: Python Import",
      },
    },
  },
  {
    "cuducos/yaml.nvim",
    ft = { "yaml" }, -- optional
    dependencies = {
      "nvim-treesitter",
    },
  },
  -- uncompiler
  {
    "p00f/godbolt.nvim",
    config = function()
      require("godbolt").setup()
    end,
    cmd = { "Godbolt", "GodboltCompiler" },
  },
  {
    "nvimdev/phoenix.nvim",
    enabled = false,
    -- dev = true,
    -- dir = "~/projects/phoenix.nvim",
    init = function()
      ---Default configuration values for Phoenix
      ---@type PhoenixConfig
      vim.g.phoenix = {
        filetypes = { "*" },
        dict = {
          capacity = 50000, -- Store up to 50k words
          min_word_length = 2, -- Ignore single-letter words
          word_pattern = "[^%s%.%_:%p%d]+", -- Word pattern
        },
        -- snippet = vim.fn.stdpath("config") .. "/snippets",
      }
    end,
  },
  {
    "JMarkin/gentags.lua",
    enabled = false,
    -- dev = true,
    -- dir = "~/projects/jmarkin/gentags.lua",
    branch = "feat/neovim-0.10",
    cond = vim.fn.executable("ctags") == 1,
    event = "VeryLazy",
    opts = {
      autostart = true,
      async = true,
      args = {
        "--extras=+r+q",
        "--exclude=\\.*",
        "--exclude=.mypy_cache",
        "--exclude=.ruff_cache",
        "--exclude=.pytest_cache",
        "--exclude=dist",
        "--exclude=target",
        "--exclude=build",
        "--exclude=.git",
        "--exclude=node_modules*",
        "--exclude=BUILD",
        "--exclude=vendor*",
        "--exclude=*.min.*",
        "--exclude=__file__",
        "--exclude=.devenv",
      },
    },
    cmd = {
      "GenCTags",
      "GenTagsEnable",
      "GenTagsDisable",
    },
  },
  {
    "chrisgrieser/nvim-scissors",
    opts = {
      snippetDir = vim.fn.stdpath("config") .. "/snippets",
      jsonFormatter = "jq",
    },
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
  },
}
