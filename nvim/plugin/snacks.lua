if vim.g.did_load_snacks_plugin then
  return
end
vim.g.did_load_snacks_plugin = true

require("lze").load({
  "snacks.nvim",
  after = function()
    require("snacks").setup({
      bigfile = { enabled = false },
      dashboard = { enabled = false },
      explorer = { enabled = false },
      indent = { enabled = false },
      input = { enabled = true },
      notifier = {
        enabled = true,
        timeout = 1000,
        level = vim.log.levels.WARN,
      },
      picker = { enabled = false },
      quickfile = { enabled = true },
      scope = { enabled = false },
      scroll = { enabled = false },
      statuscolumn = {
        enabled = true,
        folds = {
          open = true, -- show open fold icons
          git_hl = false, -- use Git Signs hl for fold icons
        },
        refresh = 200, -- ms
      },
      words = { enabled = false },
      styles = {
        notification = {
          wo = { wrap = true }, -- Wrap notifications
        },
      },
    })
  end,
  keys = {
    {
      "<space>bd",
      desc = "Buffers: delete current",
      function()
        Snacks.bufdelete.delete()
      end,
    },
    {
      "<space>bc",
      desc = "Buffers: delete other",
      function()
        Snacks.bufdelete.other()
      end,
    },
    {
      "<leader>M",
      desc = "Notifications",
      function()
        Snacks.notifier.show_history()
      end,
    },
    {
      "<leader>N",
      desc = "Neovim News",
      function()
        Snacks.win({
          file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
          width = 0.6,
          height = 0.6,
          wo = {
            spell = false,
            wrap = false,
            signcolumn = "yes",
            statuscolumn = " ",
            conceallevel = 3,
          },
        })
      end,
    },
  },
})

_G.dd = function(...)
  Snacks.debug.inspect(...)
end
_G.bt = function()
  Snacks.debug.backtrace()
end
vim.print = _G.dd -- Override print to use snacks for `:=` command

Snacks.toggle.option("hlsearch", { name = "HLSearch" }):map("<leader>th")
Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>ts")
Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>tw")
Snacks.toggle
  .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
  :map("<leader>tc")
Snacks.toggle.treesitter():map("<leader>tT")

Snacks.toggle
  .new({
    id = "diagnostic_virtuallines",
    name = "DiagnosticsVirtualLines",
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
          virtual_lines = { current_line = true },
        })
      else
        vim.diagnostic.config({
          virtual_lines = false,
        })
      end
    end,
  })
  :map("<leader>td")
