if vim.g.did_load_mini_plugin then
  return
end
vim.g.did_load_mini_plugin = true

local misc = require("mini.misc")
misc.setup()
misc.setup_auto_root(vim.g.root_pattern)

local data = vim.fn.stdpath("data")

vim.opt.shadafile = (function()
  local cwd = require("funcs").shorten_path(vim.fn.getcwd())

  local file = vim.fs.joinpath(data, "project_shada", cwd)
  vim.fn.mkdir(vim.fs.dirname(file), "p")

  return file
end)()

vim.opt.viewdir = vim.fs.joinpath(data, "view")

-- last position
misc.setup_restore_cursor({
  ignore_filetype = { "largefile", "gitcommit", "gitrebase", "svn", "hgcommit" },
})

misc.setup_termbg_sync()

lze.load({
  {
    "mini.ai",
    event = "ModeChanged",
    after = function()
      local ai = require("mini.ai")

      ai.setup({
        -- Table with textobject id as fields, textobject specification as values.
        -- Also use this to disable builtin textobjects. See |MiniAi.config|.
        custom_textobjects = {
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
        },

        -- Module mappings. Use `''` (empty string) to disable one.
        mappings = {
          -- Main textobject prefixes
          around = "a",
          inside = "i",

          -- Next/last variants
          around_next = "an",
          inside_next = "in",
          around_last = "al",
          inside_last = "il",

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
  },
})
