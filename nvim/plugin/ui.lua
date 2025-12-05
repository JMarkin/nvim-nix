if vim.g.did_load_ui_plugins then
  return
end
vim.g.did_load_ui_plugins = true

local lf = require("largefiles")
local fn = require("funcs")

lze.load({
  "local-highlight.nvim",
  on_require = "local-highlight",
  after = function()
    vim.api.nvim_set_hl(0, "LocalHighlight", { underline = true })
    require("local-highlight").setup({
      animate = {
        enabled = false,
      },
      insert_mode = false,
      file_types = {},
      hlgroup = "LocalHighlight",
    })
  end,
})
fn.augroup("local-highlight-attach", {
  vim.g.post_load_events,
  {
    pattern = "*",
    callback = function(data)
      if not lf.is_large_file(data.buf, true) then
        require("local-highlight").attach(data.buf)
      end
    end,
  },
})

lze.load({
  "whatthejump.nvim",
  keys = { "<C-i>", "<C-o>" },
})

lze.load({
  "dropbar.nvim",
  event = "BufAdd",
  after = function()
    require("dropbar").setup({
      bar = {
        enable = function(bufnr, win, _)
          bufnr = vim._resolve_bufnr(bufnr)
          if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_win_is_valid(win) then
            return false
          end

          if
            not vim.api.nvim_buf_is_valid(bufnr)
            or not vim.api.nvim_win_is_valid(win)
            or vim.fn.win_gettype(win) ~= ""
            or vim.wo[win].winbar ~= ""
            or vim.bo[bufnr].ft == "help"
          then
            return false
          end

          if lf.is_large_file(bufnr, true) then
            return false
          end

          return vim.bo[bufnr].bt == "terminal"
            or vim.bo[bufnr].ft == "markdown"
            or pcall(vim.treesitter.get_parser, bufnr)
            or not vim.tbl_isempty(vim.lsp.get_clients({
              bufnr = bufnr,
              method = vim.lsp.protocol.Methods.textDocument_documentSymbol,
            }))
        end,
      },
      sources = {
        path = {
          relative_to = function(buf, win)
            -- Show full path in oil or fugitive buffers
            local bufname = vim.api.nvim_buf_get_name(buf)
            if vim.startswith(bufname, "oil://") or vim.startswith(bufname, "fugitive://") then
              local root = bufname:gsub("^%S+://", "", 1)
              while root and root ~= vim.fs.dirname(root) do
                root = vim.fs.dirname(root)
              end
              return root
            end

            local ok, cwd = pcall(vim.fn.getcwd, win)
            return ok and cwd or vim.fn.getcwd()
          end,
        },
      },
    })
  end,
})

lze.load({
  "render-markdown.nvim",
  ft = { "markdown", "codecompanion", "Avante" },
  after = function()
    require("render-markdown").setup({
      render_modes = true,
      file_types = { "markdown", "Avante", "codecompanion", "rmd" },
      debounce = 200,
      code = {
        style = "language",
        highlight = nil,
        highlight_inline = nil,
        onceal_delimiters = false,
        border = "thick",
      },
      completions = {
        blink = { enabled = true },
        lsp = { enabled = true },
      },
    })
  end,
})

