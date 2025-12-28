if vim.g.did_load_treesitter_plugin then
  return
end
vim.g.did_load_treesitter_plugin = true

vim.g.no_plugin_maps = true

local funcs = require("funcs")

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

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "*" },
  callback = function(event)
    if funcs.get_ts(event.buf) == nil then
      return
    end
    vim.treesitter.start()
    vim.wo.foldmethod = "expr"
    vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

vim.api.nvim_create_autocmd(vim.g.post_load_events, {
  pattern = { "*" },
  once = true,
  callback = function()
    require("treesitter-context").setup({
      enable = true,
      max_lines = 5,
      min_window_height = 30,
      line_numbers = true,
      multiline_threshold = 5,
      trim_scope = "outer",
      mode = "cursor",
      zindex = 20,
      on_attach = function(buf)
        local line_count = vim.api.nvim_buf_line_count(buf)
        if line_count > 1000 then
          return false
        end
        return funcs.get_ts(buf) ~= nil
      end,
    })

    vim.api.nvim_create_autocmd({ "DiagnosticChanged" }, {
      callback = function()
        local tsc = require("treesitter-context")
        if tsc.enabled() then
          tsc.disable()
          tsc.enable()
        end
      end,
    })

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
      disable = function(buf)
        return funcs.get_ts(buf) == nil
      end,
      excluded_filetypes = { "jinja", "htmldjango" },
    })

    vim.treesitter.language.register("htmldjango", "jinja")

    require("nvim-treesitter-textobjects").setup({
      select = {
        lookahead = true,
        include_surrounding_whitespace = false,
      },

      move = {
        set_jumps = true,
      },
    })

    -- Movement keymaps using repeatable_move
    local ts_repeat = require("nvim-treesitter-textobjects.repeatable_move")
    local move = require("nvim-treesitter-textobjects.move")

    -- FUNCTION
    vim.keymap.set({ "n", "x", "o" }, "]f", function()
      move.goto_next_start("@function.outer", "textobjects")
    end, { desc = "Next function [start]" })
    vim.keymap.set({ "n", "x", "o" }, "]F", function()
      move.goto_next_end("@function.outer", "textobjects")
    end, { desc = "Next function [end]" })
    vim.keymap.set({ "n", "x", "o" }, "[f", function()
      move.goto_previous_start("@function.outer", "textobjects")
    end, { desc = "Previous function [start]" })
    vim.keymap.set({ "n", "x", "o" }, "[F", function()
      move.goto_previous_end("@function.outer", "textobjects")
    end, { desc = "Previous function [end]" })

    -- CLASS
    vim.keymap.set({ "n", "x", "o" }, "]C", function()
      move.goto_next_start("@class.outer", "textobjects")
    end, { desc = "Next class [start]" })
    vim.keymap.set({ "n", "x", "o" }, "]o", function()
      move.goto_next_end("@class.outer", "textobjects")
    end, { desc = "Next class [end]" })
    vim.keymap.set({ "n", "x", "o" }, "[C", function()
      move.goto_previous_start("@class.outer", "textobjects")
    end, { desc = "Previous class [start]" })
    vim.keymap.set({ "n", "x", "o" }, "[o", function()
      move.goto_previous_end("@class.outer", "textobjects")
    end, { desc = "Previous class [end]" })

    -- LOOP
    vim.keymap.set({ "n", "x", "o" }, "]l", function()
      move.goto_next_start({ "@loop.inner", "@loop.outer" }, "textobjects")
    end, { desc = "Next loop [start]" })
    vim.keymap.set({ "n", "x", "o" }, "[l", function()
      move.goto_previous_start({ "@loop.inner", "@loop.outer" }, "textobjects")
    end, { desc = "Previous loop [start]" })

    -- FOLD
    vim.keymap.set({ "n", "x", "o" }, "]z", function()
      move.goto_next_start("@fold", "folds")
    end, { desc = "Next fold [start]" })
    vim.keymap.set({ "n", "x", "o" }, "[z", function()
      move.goto_previous_start("@fold", "folds")
    end, { desc = "Previous fold [start]" })

    -- CONDITIONAL
    vim.keymap.set({ "n", "x", "o" }, "]i", function()
      move.goto_next("@conditional.outer", "textobjects")
    end, { desc = "Next conditional" })
    vim.keymap.set({ "n", "x", "o" }, "[i", function()
      move.goto_previous("@conditional.outer", "textobjects")
    end, { desc = "Previous conditional" })

    -- Repeat movement with ; and ,
    vim.keymap.set({ "n", "x", "o" }, ".", ts_repeat.repeat_last_move_next)
    vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat.repeat_last_move_previous)

    -- Make f, F, t, T repeatable
    vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat.builtin_f_expr, { expr = true })
    vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat.builtin_F_expr, { expr = true })
    vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat.builtin_t_expr, { expr = true })
    vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat.builtin_T_expr, { expr = true })

    -- Swap keymaps with <leader>cs prefix
    local swap = require("nvim-treesitter-textobjects.swap")
    vim.keymap.set("n", "<leader>csp", function()
      swap.swap_next("@parameter.inner")
    end, { desc = "Swap param next" })
    vim.keymap.set("n", "<leader>csP", function()
      swap.swap_previous("@parameter.inner")
    end, { desc = "Swap param prev" })
    vim.keymap.set("n", "<leader>csf", function()
      swap.swap_next("@function.outer")
    end, { desc = "Swap function next" })
    vim.keymap.set("n", "<leader>csF", function()
      swap.swap_previous("@function.outer")
    end, { desc = "Swap function prev" })
  end,
})
