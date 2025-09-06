if vim.g.did_load_treesitter_plugin then
  return
end
vim.g.did_load_treesitter_plugin = true

local is_large_file = require("largefiles").is_large_file
local FILE_TYPE = require("largefiles").FILE_TYPE

---@diagnostic disable-next-line: unused-local
local is_disable = function(_lang, buf)
  local _type = is_large_file(buf)

  local r = _type ~= FILE_TYPE.NORMAL

  return r
  -- return _type == FILE_TYPE.READ_ONLY or _type == FILE_TYPE.LARGE_SIZE
end

lze.load({
  "nvim-treesitter-context",
  on_plugin = "nvim-treesitter",
  after = function()
    local tsc = require("treesitter-context")
    tsc.setup({
      enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
      max_lines = 5, -- How many lines the window should span. Values <= 0 mean no limit.
      min_window_height = 30, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
      line_numbers = true,
      multiline_threshold = 5, -- Maximum number of lines to show for a single context
      trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
      mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
      -- Separator between context and content. Should be a single character string, like '-'.
      -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
      -- separator = "-",
      zindex = 20, -- The Z-index of the context window
      on_attach = function(buf)
        local line_count = vim.api.nvim_buf_line_count(buf)
        if line_count > 1000 then
          return false
        end
        return not is_disable(nil, buf)
      end, -- (fun(buf: integer): boolean) return false to disable attaching
    })
    vim.api.nvim_create_autocmd({ "DiagnosticChanged" }, {
      callback = function()
        if tsc.enabled() then
          tsc.disable()
          tsc.enable()
        end
      end,
    })
  end,
})

lze.load({
  "nvim-treesitter-textobjects",
  on_plugin = "nvim-treesitter",
})

lze.load({
  "nvim-yati",
  on_plugin = "nvim-treesitter",
})

lze.load({
  "hlargs.nvim",
})

lze.load({
  "nvim-treesitter",
  event = vim.g.post_load_events,
  on_require = { "nvim-treesitter.configs" },
  before = function()
    local prev = vim.treesitter.language.get_lang
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.treesitter.language.get_lang = function(...)
      lze.trigger_load("nvim-treesitter")
      return prev(...)
    end
  end,
  after = function()
    require("nvim-treesitter.configs").setup({
      autotag = {
        enable = false,
        disable = is_disable,
      },
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = true,
        disable = is_disable,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<cr>",
          node_incremental = "<cr>",
          scope_incremental = "<tab>",
          node_decremental = "<s-tab>",
        },
        disable = is_disable,
      },
      yati = {
        enable = true,
        disable = is_disable,
      },
      indent = {
        enable = false,
        disable = is_disable,
      },
      matchup = {
        enable = false,
        include_match_words = true,
        disable = is_disable,
      },
    })

    vim.treesitter.language.register("htmldjango", "jinja")

    local colorpalette = {
      { fg = "#EB75D6" },
      { fg = "#D49DA5" },
      { fg = "#ef9062" },
      { fg = "#e75a7c" },
      { fg = "#57a5e5" },
      { fg = "#3AC6BE" },
      { fg = "#8997F5" },
      { fg = "#7FEC35" },
      { fg = "#8FB272" },
    }

    require("hlargs").setup({
      use_colorpalette = true,
      colorpalette = colorpalette,
      paint_arg_declarations = true,
      paint_arg_usages = true,
      paint_catch_blocks = {
        declarations = true,
        usages = true,
      },
      extras = {
        named_parameters = true,
      },
      excluded_argnames = {
        declarations = {},
        usages = {
          usages = {
            python = {},
            lua = {},
          },
        },
      },
      disable = is_disable,
      excluded_filetypes = { "jinja", "htmldjango" },
    })
  end,
})
