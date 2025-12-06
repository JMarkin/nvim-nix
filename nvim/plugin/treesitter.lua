if vim.g.did_load_treesitter_plugin then
  return
end
vim.g.did_load_treesitter_plugin = true

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
  end,
})

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
