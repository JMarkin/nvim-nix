if vim.g.did_load_git_plugin then
  return
end
vim.g.did_load_git_plugin = true

local augroup = vim.api.nvim_create_augroup
function DiffviewToggle()
  local lib = require("diffview.lib")

  local view = lib.get_current_view()
  if view then
    vim.cmd(":DiffviewClose")
  else
    vim.cmd(":DiffviewOpen")
  end
end
local gr = augroup("DiffView", { clear = true })
vim.api.nvim_create_autocmd("User", {
  group = gr,
  pattern = "DiffviewViewEnter",
  callback = function(event)
    vim.keymap.set("n", "q", DiffviewToggle, { silent = true })
  end,
})

vim.api.nvim_create_autocmd("User", {
  group = gr,
  pattern = "DiffviewViewLeave",
  callback = function()
    vim.keymap.del("n", "q")
  end,
})

lze.load({
  {
    "gitsigns.nvim",
    after = function()
      require("gitsigns").setup({})
    end,
    event = vim.g.pre_load_events,
    keys = {
      { "<leader>gb", ":Gitsign blame_line<cr>", desc = "Git: blake line" },
      { "<leader>gB", ":Gitsign blame<cr>", desc = "Git: blame" },
      { "<leader>gs", ":Gitsign stage_hunk<cr>", desc = "Git: stage hunk", mode = { "n", "v" } },
      { "<leader>gS", ":Gitsign stage_buffer<cr>", desc = "Git: stage buffer" },
      { "<leader>gu", ":Gitsign undo_stage_hunk<cr>", desc = "Git: undo stage hunk", mode = { "n", "v" } },
      { "<leader>gr", ":Gitsign reset_hunk<cr>", desc = "Git: reset hunk", mode = { "n", "v" } },
      { "<leader>gR", ":Gitsign reset_buffer<cr>", desc = "Git: reset buffer" },
      { "<leader>gp", ":Gitsign preview_hunk_inline<cr>", desc = "Git: preview hunk" },
      { "ih", ":<C-U>Gitsigns select_hunk<CR>", desc = "Git: select hunk", mode = { "o", "x" } },
    },
  },
  {
    "diffview.nvim",
    keys = {
      { "<leader>gD", DiffviewToggle, silent = true, desc = "Git: Diffview toggle" },
      { "<leader>gh", ":DiffviewFileHistory %<cr>", silent = true, desc = "Git: DiffviewFileHistory current" },
      { "<leader>gH", ":DiffviewFileHistory<cr>", silent = true, desc = "Git: DiffviewFileHistory current" },
      { "<leader>gh", ":'<,'>DiffviewFileHistory<cr>", "Log visual selection", mode = "v" },
    },
    cmd = {
      "DiffviewOpen",
      "DiffviewFileHistory",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
    },
    after = function()
      require("diffview").setup({
        signs = {
          fold_closed = "+",
          fold_open = "-",
          done = "✓",
        },
        hooks = {
          diff_buf_read = function(bufnr)
            bufnr = vim._resolve_bufnr(bufnr)
            vim.b[bufnr].no_winbar = true
          end,
        },
        view = {
          default = {
            layout = "diff2_horizontal",
            disable_diagnostics = true,
            winbar_info = true,
          },
          merge_tool = {
            layout = "diff4_mixed",
            disable_diagnostics = true,
          },
          file_history = {
            layout = "diff2_horizontal",
          },
        },
      })
    end,
  },
})
