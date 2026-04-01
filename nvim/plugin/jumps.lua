if vim.g.did_load_jumps_plugin then
  return
end
vim.g.did_load_jumps_plugin = true

lze.load({
  {
    "eyeliner.nvim",
    keys = { "t", "f", "T", "F" },
    after = function()
      require("eyeliner").setup({
        highlight_on_key = true,
        dim = true,
        default_keymaps = false,
      })
      local function eyeliner_jump(key)
        local forward = vim.list_contains({ "t", "f" }, key)
        return function()
          require("eyeliner").highlight({ forward = forward })
          return require("demicolon.jump").horizontal_jump(key)()
        end
      end

      local nxo = { "n", "x", "o" }
      local key_opts = { expr = true }

      vim.keymap.set(nxo, "f", eyeliner_jump("f"), key_opts)
      vim.keymap.set(nxo, "F", eyeliner_jump("F"), key_opts)
      vim.keymap.set(nxo, "t", eyeliner_jump("t"), key_opts)
      vim.keymap.set(nxo, "T", eyeliner_jump("T"), key_opts)
    end,
  },
  {
    "demicolon.nvim",
    -- stylua: ignore start
    keys = {
        -- plugin
        ";", ",",
        --  t/T/f/F key mappings
        -- "t", "f", "T", "F",
        --  lezy load key mappings
        "]", "[",
        -- key mappings to jump to diganostics. See demicolon.keymaps.create_default_diagnostic_keymaps
        "]d", "[d",
        -- quickfix
        "]q", "[q", "]<C-q>", "[<C-q>",
        -- local list
        "]l", "[l", "]<C-l>", "]<C-l>",
        -- spell
        "]s", "[s",
        -- gitsign
        "]c", "[c",
    },
    -- stylua: ignore end
    deps_on = {
      "eyeliner.nvim",
      "nvim-treesitter",
    },
    on_require = { "demicolon.jump" },
    after = function()
      require("demicolon").setup({
        -- Create default keymaps
        keymaps = {
          disabled_keys = { 'p', 'I', 'A' },
          -- Create t/T/f/F key mappings
          horizontal_motions = false,
          -- Create ; and , key mappings
          repeat_motions = "stateful",
        },
      })
    end,
    -- event = vim.g.post_load_events,
  },
  {
    "flash.nvim",
    after = function()
      require("flash").setup({
        modes = {
          search = {
            enabled = false,
          },
          char = {
            enabled = false,
          },
        },
        label = {
          rainbow = {
            enabled = false,
          },
        },
        exclude = {
          "notify",
          "cmp_menu",
          "noice",
          "flash_prompt",
          function(win)
            return require("largefiles").is_large_file(win.buf, true)
          end,
        },
      })
    end,
    keys = {
      {
        "ss",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        "st",
        mode = { "n", "o", "x" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
      {
        "sR",
        mode = { "o", "x" },
        function()
          require("flash").treesitter_search()
        end,
        desc = "Flash Treesitter Search",
      },
    },
  },
})
