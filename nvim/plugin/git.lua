if vim.g.did_load_git_plugin then
  return
end
vim.g.did_load_git_plugin = true

local autocmd = vim.api.nvim_create_autocmd
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
      require("gitsigns").setup({
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map("n", "]c", function()
            if vim.wo.diff then
              return "]c"
            end
            vim.schedule(function()
              gs.next_hunk({ preview = true })
            end)
            return "<Ignore>"
          end, { expr = true, desc = "Git: next hunk" })

          map("n", "[c", function()
            if vim.wo.diff then
              return "[c"
            end
            vim.schedule(function()
              gs.prev_hunk({ preview = true })
            end)
            return "<Ignore>"
          end, { expr = true, desc = "Git: prev hunk" })
        end,
      })
    end,
    event = vim.g.pre_load_events,
    keys = {
      "[c",
      "]c",
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
    "vim-fugitive",
    cmd = {
      "Git",
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
        hooks = {
          diff_buf_read = function(bufnr)
            vim.b[bufnr].no_winbar = true
          end,
        },
        view = {
          default = {
            layout = "diff2_horizontal",
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

