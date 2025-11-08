if vim.g.did_load_toggles_plugin then
  return
end
vim.g.did_load_toggles_plugin = true

---@class toggle.Opts
---@field name string
---@field keymap string
---@field desc string
---@field get fun(): boolean | nil
---@field set fun(boolean)

---@param opts toggle.Opts
local function setup(opts)
  vim.keymap.set("n", opts.keymap, function()
    local value = opts.get()
    if value == nil then
      return
    end
    opts.set(value)
  end, { desc = opts.desc })
end

setup({
  name = "diagnostic lines",
  keymap = "<leader>td",
  desc = "Toggle: disagnostic lines",
  get = function()
    local current = vim.diagnostic.config()
    if not current then
      return false
    end
    if not current.virtual_lines then
      return false
    end

    return current.virtual_lines.current_line
  end,
  set = function(state)
    if state then
      vim.diagnostic.config({
        virtual_lines = false,
      })
    else
      vim.diagnostic.config({
        virtual_lines = { current_line = true },
      })
    end
  end,
})

setup({
  name = "hlsearch",
  keymap = "<leader>th",
  desc = "Toggle: hlsearch",
  get = function()
    return vim.o.hlsearch
  end,
  set = function(state)
    if state then
      vim.o.hlsearch = false
    else
      vim.o.hlsearch = true
    end
  end,
})

