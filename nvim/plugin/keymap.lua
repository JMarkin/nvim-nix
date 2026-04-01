if vim.g.did_load_keymap_plugin then
  return
end
vim.g.did_load_keymap_plugin = true

local default_vim_keymap_set = vim.keymap.set

vim.keymap.set = function(mode, lhs, rhs, opts)
  if type(lhs) == "table" then
    for _, key in ipairs(lhs) do
      default_vim_keymap_set(mode, key, rhs, opts)
    end
  else
    default_vim_keymap_set(mode, lhs, rhs, opts)
  end
end

local map = vim.keymap.set

local u = require("funcs")

-- Disable arrow keys in normal mode
vim.keymap.set("n", "<left>", '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set("n", "<right>", '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set("n", "<up>", '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set("n", "<down>", '<cmd>echo "Use j to move!!"<CR>')

vim.keymap.set({ "n" }, { "<leader>q", "<space>q" }, ":q<cr>", { desc = "Quit", silent = true })

vim.keymap.set({ "n", "v" }, "<C-d>", "10jzz")
vim.keymap.set({ "n", "v" }, "<C-u>", "10kzz")
vim.keymap.set({ "n" }, "<C-w>>", "10<C-w>>")
vim.keymap.set({ "n" }, "<C-w><", "10<C-w><")
vim.keymap.set({ "n" }, "<C-w>+", "5<C-w>+")
vim.keymap.set({ "n" }, "<C-w>-", "5<C-w>-")

-- vim.keymap.set({ "n" }, "o", "o<Esc>", { desc = "Add line under" })
-- vim.keymap.set({ "n" }, "O", "O<Esc>", { desc = "Add line prev" })

vim.keymap.set({ "n" }, { "<leader>w", "<leader>'" }, ":w<CR>", { silent = true, desc = "normal mode: save" })
vim.keymap.set(
  { "v" },
  { "<leader>w", "<leader>'" },
  "<Esc>:w<CR>",
  { desc = "visual mode: escape to normal and save", silent = true }
)

vim.keymap.set(
  { "v" },
  { "<leader>W" },
  "<Esc>:wa<CR>",
  { silent = true, desc = "visual mode: escape to normal and save" }
)

-- Tabpages
---@param tab_action function
---@param default_count number?
---@return function
local function tabswitch(tab_action, default_count)
  return function()
    local count = default_count or vim.v.count
    local num_tabs = vim.fn.tabpagenr("$")
    if num_tabs >= count then
      tab_action(count ~= 0 and count or nil)
      return
    end
    vim.cmd.tablast()
  end
end
vim.keymap.set({ "n", "x" }, "gt", tabswitch(vim.cmd.tabnext), { desc = "Tabs: next" })
vim.keymap.set({ "n", "x" }, "gT", tabswitch(vim.cmd.tabprev), { desc = "Tabs: prev" })
vim.keymap.set({ "n", "x" }, "gy", tabswitch(vim.cmd.tabprev), { desc = "Tabs: prev" }) -- gT is too hard to press

vim.keymap.set("n", "<space>t", ":$tabnew<CR>", { desc = "Tabs: new" })
vim.keymap.set("n", "<space>[", ":-tabmove<CR>", { desc = "Tabs: move to prev" })
vim.keymap.set("n", "<space>]", ":+tabmove<CR>", { desc = "Tabs: move to next" })

for i = 1, 9, 1 do
  vim.keymap.set({ "n", "x" }, "<space>" .. i, tabswitch(vim.cmd.tabnext, i), { desc = "Tabs: go to " .. i })
  -- vim.keymap.set({ "t" }, "<c-t>" .. i, tabswitch(vim.cmd.tabnext, i), { desc = "Tabs: go to " .. i })
end

vim.keymap.set("n", "<leader>lcl", function()
  local s = string.format("%s:%s", vim.fn.expand("%"), vim.fn.line("."))
  vim.notify(string.format("Copied reference: %s", s))
  vim.fn.setreg("+", s)
end, { noremap = true, desc = "Copy as: line" })

vim.keymap.set("n", "<A-g>", ":DiffviewOpen<cr>", { desc = "DIFF" })

vim.keymap.set("n", "<space>D", ":DBUIToggle<CR>", { desc = "DBUI" })

vim.keymap.set(
  "n",
  "<space>W",
  (function()
    local enabled = false
    return function()
      if not enabled then
        vim.cmd([[let &winwidth = &columns * 7 / 10 ]])
        vim.cmd([[let &winheight = &lines * 7 / 10 ]])
      else
        vim.opt.winwidth = vim.g.default_winwidth
        vim.opt.winheight = vim.g.default_winheight
      end
      enabled = not enabled
    end
  end)(),
  { desc = "Toggle autoresize height width buffers of window" }
)
-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
vim.keymap.set({ "n", "x", "o" }, "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
vim.keymap.set({ "n", "x", "o" }, "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })

-- copy paste https://github.com/Wansmer/nvim-config/blob/main/lua/mappings.lua
-- ============================================================================
-- Text edit
-- ============================================================================
-- WARNING: use ':' instead <Cmd> in visual mode (x, s, v) + ex command
local function duplicate_line()
  local times = vim.v.count == 0 and 1 or vim.v.count
  for _ = 1, times, 1 do
    vim.cmd.copy(".")
  end
end

local function duplicate_selection()
  local restore_autocmd = u.disable_autocmd("NumberToggle")

  local times = vim.v.count == 0 and 1 or vim.v.count
  for _ = 1, times, 1 do
    vim.api.nvim_feedkeys(vim.keycode(":copy.-1<Cr>gv"), "n", true)
  end

  restore_autocmd()
end

local function move_line(op)
  return function()
    local start = op == "+" and 1 or 2
    local count = vim.v.count
    local times = count == 0 and start or (op == "+" and count or count + 1)
    local ok, _ = pcall(vim.cmd.move, op .. times)
    if ok then
      vim.cmd.norm("==")
    end
  end
end

local function move_selected(op)
  return function()
    local restore_autocmd = u.disable_autocmd("NumberToggle")

    -- ":move'>+<Cr>gv=gv"
    -- ":move'<-2<Cr>gv=gv"
    local start = op == "+" and "" or 2
    local count = vim.v.count
    local times = count == 0 and start or (op == "+" and count or count + 1)
    local mark = op == "+" and "'>" or "'<"
    vim.api.nvim_feedkeys(vim.keycode(":move" .. mark .. op .. times .. "<Cr>gv=gv"), "n", true)

    restore_autocmd()
  end
end

map("n", "<Leader>d", duplicate_line, { desc = "Duplicate current line" })
map("x", "<Leader>d", duplicate_selection, { desc = "Duplicate current selection and reselect" })
map("n", "<C-n>", move_line("+"), { desc = "Move current line downward" })
map("n", "<C-p>", move_line("-"), { desc = "Move current line upward" })
map("x", "<C-n>", move_selected("+"), { desc = "Move current selection downward and reselect" })
map("x", "<C-p>", move_selected("-"), { desc = "Move current selection upward and reselect" })
map("x", "<", "<gv", { desc = "One indent left and reselect" })
map("x", ">", ">gv|", { desc = "One indent right and reselect" })
map("x", "<S-Tab>", "<gv", { desc = "One indent left and reselect" })
map("x", "<Tab>", ">gv|", { desc = "One indent right and reselect" })
map("x", "p", '"_c<Esc>p', { desc = "Paste without copying into register" })

map("n", "Q", "q", { desc = "Start recording macro" })
map("n", "[q", "<Cmd>cnext<Cr>", { desc = "Go to next match in quickfix list" })
map("n", "]q", "<Cmd>cprev<Cr>", { desc = "Go to next match in quickfix list" })
