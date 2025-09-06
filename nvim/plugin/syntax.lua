if vim.g.did_load_syntax_plugin then
  return
end
vim.g.did_load_syntax_plugin = true

local fn = require("funcs")

vim.cmd([[
        syntax on
    ]])
vim.g.polyglot_disabled = { "ftdetect", "autoindent" }

lze.load({
  "vim-polyglot",
  event = vim.g.pre_load_events,
})

-- fastsyntax
fn.augroup("fastsyntax", {
  { "BufWinEnter", "Syntax" },
  {
    pattern = "*",
    command = "syn sync minlines=256 maxlines=256",
  },
})

fn.augroup("omnifuncsetter", {
  { "FileType" },
  {
    pattern = "*",
    callback = function()
      if vim.opt.omnifunc == "" then
        vim.opt_local.omnifunc = "syntaxcomplete#Complete"
      end
    end,
  },
})
