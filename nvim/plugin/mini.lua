if vim.g.did_load_mini_plugin then
  return
end
vim.g.did_load_mini_plugin = true

local misc = require("mini.misc")
misc.setup()
-- misc.setup_auto_root(vim.g.root_pattern)

local data = vim.fn.stdpath("data")

vim.opt.shadafile = (function()
  local cwd = require("funcs").shorten_path(vim.fn.getcwd())

  local file = vim.fs.joinpath(data, "project_shada", cwd)
  vim.fn.mkdir(vim.fs.dirname(file), "p")

  return file
end)()

vim.opt.viewdir = vim.fs.joinpath(data, "view")

-- last position
-- misc.setup_restore_cursor({
--   ignore_filetype = { "largefile", "gitcommit", "gitrebase", "svn", "hgcommit" },
-- })

misc.setup_termbg_sync()

lze.load({
  "mini.ai",
  event = "ModeChanged",
  after = function()
    local ai = require("mini.ai")

    ai.setup({
      -- Table with textobject id as fields, textobject specification as values.
      -- Also use this to disable builtin textobjects. See |MiniAi.config|.
      custom_textobjects = {
        f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
        C = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
        l = ai.gen_spec.treesitter({ a = "@loop.outer", i = "@loop.inner" }),
        i = ai.gen_spec.treesitter({ a = "@conditional.outer", i = "@conditional.inner" }),
      },

      -- Module mappings. Use `''` (empty string) to disable one.
      mappings = {
        -- Main textobject prefixes
        around = "a",
        inside = "i",

        -- Next/last variants
        around_next = "",
        inside_next = "",
        around_last = "",
        inside_last = "",

        -- Move cursor to corresponding edge of `a` textobject
        goto_left = "g[",
        goto_right = "g]",
      },

      -- Number of lines within which textobject is searched
      n_lines = 50,

      -- How to search for object (first inside current line, then inside
      -- neighborhood). One of 'cover', 'cover_or_next', 'cover_or_prev',
      -- 'cover_or_nearest', 'next', 'previous', 'nearest'.
      search_method = "cover_or_next",

      -- Whether to disable showing non-error feedback
      silent = false,
    })
  end,
})

lze.load({
  "mini.surround",
  event = vim.g.post_load_events,
  after = function()
    local surround = require("mini.surround")
    surround.setup({
        highlight_duration = 500,
        -- Module mappings. Use `''` (empty string) to disable one.
        mappings = {
          add = "sa", -- Add surrounding in Normal and Visual modes
          delete = "sd", -- Delete surrounding
          find = "sf", -- Find surrounding (to the right)
          find_left = "sF", -- Find surrounding (to the left)
          highlight = "sh", -- Highlight surrounding
          replace = "sr", -- Replace surrounding

          suffix_last = "l", -- Suffix to search with "prev" method
          suffix_next = "n", -- Suffix to search with "next" method
        },
      }
    )
  end,
})
