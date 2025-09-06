vim.keymap.set("n", "<space>f", "<cmd>Oil<cr>", { noremap = true, desc = "Netrw: open" })

local detail = false

-- Declare a global function to retrieve the current directory
function _G.get_oil_winbar()
  local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
  local dir = require("oil").get_current_dir(bufnr)
  if dir then
    return vim.fn.fnamemodify(dir, ":~")
  else
    -- If there is no current directory (e.g. over ssh), just show the buffer name
    return vim.api.nvim_buf_get_name(0)
  end
end

vim.api.nvim_create_autocmd("User", {
  pattern = "OilActionsPost",
  callback = function(event)
    if event.data.actions.type == "move" then
      Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
    end
  end,
})

return {
  {
    "stevearc/oil.nvim",
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      win_options = {
        winbar = "%!v:lua.get_oil_winbar()",
      },
      watch_for_changes = true,
      use_default_keymaps = false,
      keymaps = {
        ["g?"] = { "actions.show_help", mode = "n" },
        ["q"] = {
          desc = "close and restore prev buffer",
          callback = function()
            require("oil").close()
          end,
        },
        ["<CR>"] = "actions.select",
        ["<C-v>"] = { "actions.select", opts = { vertical = true } },
        ["<C-s>"] = { "actions.select", opts = { horizontal = true } },
        ["<C-t>"] = { "actions.select", opts = { tab = true } },
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = { "actions.close", mode = "n" },
        ["<C-r>"] = "actions.refresh",
        ["-"] = { "actions.parent", mode = "n" },
        ["_"] = { "actions.open_cwd", mode = "n" },
        ["<tab>"] = "actions.select",
        ["<s-tab>"] = { "actions.parent", mode = "n" },
        ["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
        ["s"] = { "actions.change_sort", mode = "n" },
        ["gh"] = { "actions.toggle_hidden", mode = "n" },
        ["gd"] = {
          desc = "Toggle file detail view",
          callback = function()
            detail = not detail
            if detail then
              require("oil").set_columns({ "icon", "permissions", "size", "mtime" })
            else
              require("oil").set_columns({ "icon" })
            end
          end,
        },
      },
      preview_win = {
        -- A function that returns true to disable preview on a file e.g. to avoid lag
        disable_preview = function(filename)
          local funcs = require("funcs")
          local path = filename
          if not funcs.is_text(path) then
            return true
          end

          -- if file > 5 MB or not text -> not preview
          local size = funcs.get_size(path)
          if type(size) ~= "number" then
            return true
          end

          if size > 5 then
            return true
          end

          -- len
          local len = funcs.maxline(path)
          if type(len) ~= "number" then
            return true
          end

          if len > vim.o.synmaxcol then
            return true
          end

          return false
        end,
        -- Window-local options to use for preview window buffers
        win_options = {},
      },
    },
    -- Optional dependencies
    dependencies = { "echasnovski/mini.icons" },
    lazy = false,
  },
}
