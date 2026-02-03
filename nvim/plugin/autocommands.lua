if vim.g.did_load_autocommands_plugin then
  return
end
vim.g.did_load_autocommands_plugin = true

local fn = require("funcs")

-- Show cursor line only in active window.
-- https://github.com/folke/dot/blob/master/nvim/lua/config/autocmds.lua

fn.augroup("cursoronlyactivate", {
  { "InsertLeave", "WinEnter" },
  {
    callback = function()
      if vim.wo.previewwindow then
        return
      end

      if vim.w.auto_cursorline then
        vim.wo.cursorline = true
        vim.w.auto_cursorline = false
      end
    end,
  },
}, {
  { "InsertEnter", "WinLeave" },
  {
    callback = function()
      if vim.wo.previewwindow then
        return
      end

      if vim.wo.cursorline then
        vim.w.auto_cursorline = true
        vim.wo.cursorline = false
      end
    end,
  },
})

-- Persistent Folds
fn.augroup("auto_view", {
  { "BufWinLeave", "BufWritePost", "WinLeave" },
  {
    desc = "Save view with mkview for real files",
    callback = function(args)
      if vim.b[args.buf].view_activated then
        vim.cmd.mkview({ mods = { emsg_silent = true } })
      end
    end,
  },
}, {
  "BufWinEnter",
  {
    desc = "Try to load file view if available and enable view saving for real files",
    callback = function(args)
      if not vim.b[args.buf].view_activated then
        local filetype = vim.api.nvim_get_option_value("filetype", { buf = args.buf })
        local buftype = vim.api.nvim_get_option_value("buftype", { buf = args.buf })
        local ignore_filetypes = { "gitcommit", "gitrebase", "svg", "hgcommit" }
        if buftype == "" and filetype and filetype ~= "" and not vim.tbl_contains(ignore_filetypes, filetype) then
          vim.b[args.buf].view_activated = true
          vim.cmd.loadview({ mods = { emsg_silent = true } })
        end
      end
    end,
  },
})

-- Use 'q' to quit from common plugins
fn.augroup("quit", {
  "FileType",
  {
    pattern = {
      "help",
      "man",
      "lspinfo",
      "qf",
      "notify",
      "startuptime",
      "checkhealth",
      "PlenaryTestPopup",
      "dbout",
      "gitsigns-blame",
      "tsplayground",
    },
    callback = function(event)
      vim.opt_local.wrap = false
      vim.bo[event.buf].buflisted = false
      vim.schedule(function()
        vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
      end)
    end,
  },
})

fn.augroup("spell", {
  "FileType",
  {
    pattern = { "gitcommit", "markdown", "text" },
    callback = function()
      vim.opt_local.spell = true
    end,
  },
})

fn.augroup("tempfile", {
  { "BufWritePre" },
  {
    pattern = { "/tmp/*", "COMMIT_EDITMSG", "MERGE_MSG", "*.tmp", "*.bak" },
    command = "setlocal noundofile",
  },
})

-- largefiles

-- nubmer toggles

vim.defer_fn(function()
  if vim.g.numbertoggle then
    fn.augroup("NumberToggle", {
      { "InsertLeave", "CmdlineLeave" },
      {
        callback = function(event)
          if vim.b.numbertoggle_disabled == 1 then
            return
          end
          if
            vim.bo[event.buf].buflisted
            and vim.opt_local.number
            and vim.api.nvim_get_mode().mode ~= "i"
            and string.find(vim.fn.bufname(event.buf), "term://") == nil
          then
            vim.opt.relativenumber = true
          end
        end,
      },
    }, {
      { "InsertEnter", "CmdlineEnter" },
      {
        callback = function(event)
          if vim.b.numbertoggle_disabled == 1 then
            return
          end
          if
            vim.bo[event.buf].buflisted
            and vim.opt_local.number
            and string.find(vim.fn.bufname(event.buf), "term://") == nil
          then
            vim.opt.relativenumber = false
            vim.cmd("redraw!")
          end
        end,
      },
    })
  end
end, 100)

fn.augroup("Format Options", {
  "BufReadPost",
  {
    callback = function()
      vim.opt_local.formatoptions = vim.opt_local.formatoptions
        - "a" -- Auto formatting is BAD.
        - "t" -- Don't auto format my code. I got linters for that.
        + "c" -- In general, I like it when comments respect textwidth
        + "q" -- Allow formatting comments w/ gq
        - "o" -- O and o, don't continue comments
        + "r" -- But do continue when pressing enter.
        + "n" -- Indent past the formatlistpat, not underneath it.
        - "2" -- I'm not in gradeschool anymore
        + "j" -- Auto-remove comments if possible.
        + "p" -- I want under stand shorts
    end,
  },
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
fn.augroup("autocreatedir", {
  { "BufWritePre" },
  {
    callback = function(event)
      if event.match:match("^%w%w+://") then
        return
      end
      local file = vim.uv.fs_realpath(event.match) or event.match
      vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
    end,
  },
})

-- Check if we need to reload the file when it changed
fn.augroup("checktime", {
  { "BufEnter", "CursorHold", "CursorHoldI", "FocusGained", "TermLeave", "TermClose" },
  {
    command = "if &buftype == '' && mode() != 'c' && getcmdwintype() == '' | checktime | endif",
    pattern = { "*" },
  },
})

if vim.env.TERM == "alacritty" then
  vim.api.nvim_create_autocmd("ExitPre", {
    once = true,
    command = "set guicursor=a:ver90",
    desc = "Set cursor back to beam when leaving Neovim.",
  })
end

fn.augroup("after ui", {
  { "UIEnter" },
  {
    callback = function(event)
      vim.cmd.packadd("nohlsearch")
    end,
  },
})

vim.api.nvim_create_autocmd("BufHidden", {
  desc = "Delete [No Name] buffers",
  callback = function(data)
    if data.file == "" and vim.bo[data.buf].buftype == "" and not vim.bo[data.buf].modified then
      vim.schedule(function()
        pcall(vim.api.nvim_buf_delete, data.buf, {})
      end)
    end
  end,
})
