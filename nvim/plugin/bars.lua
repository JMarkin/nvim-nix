if vim.g.did_load_bar_plugin then
  return
end
vim.g.did_load_bar_plugin = true

local lf = require("largefiles")

lze.load({
  "dropbar.nvim",
  event = "BufAdd",
  after = function()
    require("dropbar").setup({
      bar = {
        enable = function(buf, win, _)
          buf = vim._resolve_bufnr(buf)
          if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
            return false
          end

          if
            not vim.api.nvim_buf_is_valid(buf)
            or not vim.api.nvim_win_is_valid(win)
            or vim.fn.win_gettype(win) ~= ""
            or vim.wo[win].winbar ~= ""
            or vim.bo[buf].ft == "help"
          then
            return false
          end

          if lf.is_large_file(buf, true) then
            return false
          end

          return vim.bo[buf].bt == "terminal"
            or vim.bo[buf].ft == "markdown"
            or pcall(vim.treesitter.get_parser, buf)
            or not vim.tbl_isempty(vim.lsp.get_clients({
              bufnr = buf,
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
