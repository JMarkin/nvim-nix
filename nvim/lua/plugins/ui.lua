return {
  -- ui components
  { "MunifTanjim/nui.nvim", lazy = true },
  {
    "ibhagwan/smartyank.nvim",
    enabled = true,
    event = "ModeChanged",
    opts = {
      highlight = {
        enabled = true, -- highlight yanked text
        timeout = 100,
      },
    },
    config = function(_, opts)
      require("smartyank").setup(opts)
      vim.api.nvim_create_autocmd("FocusGained", {
        callback = function()
          local loaded_content = vim.fn.getreg("+")
          if loaded_content ~= "" then
            vim.fn.setreg('"', loaded_content)
          end
        end,
      })
    end,
  },

  {
    "DanilaMihailov/beacon.nvim",
    -- enabled = false,
    cond = function()
      return not vim.g.neovide
    end,
    opts = {
      enabled = function()
        local line_count = vim.api.nvim_buf_line_count(vim.api.nvim_get_current_buf())
        if line_count > 1000 then
          return false
        end
        return true
      end, --- (boolean | fun():boolean) check if enabled
      speed = 2, --- integer speed at wich animation goes
      width = 40, --- integer width of the beacon window
      winblend = 70, --- integer starting transparency of beacon window :h winblend
      fps = 60, --- integer how smooth the animation going to be
      min_jump = 10, --- integer what is considered a jump. Number of lines
      cursor_events = { "CursorMoved" }, -- table<string> what events trigger check for cursor moves
      window_events = { "WinEnter", "FocusGained" }, -- table<string> what events trigger cursor highlight
      highlight = { bg = "white", ctermbg = 15 }, -- vim.api.keyset.highlight table passed to vim.api.nvim_set_hl
    },
    event = { "BufAdd" },
  },
  {
    "tzachar/local-highlight.nvim",
    lazy = true,
    -- enabled = false,
    opts = {
      insert_mode = false,
      file_types = {},
      hlgroup = "LocalHighlight",
    },
    init = function()
      local fn = require("funcs")
      local lf = require("largefiles")
      vim.api.nvim_set_hl(0, "LocalHighlight", { underline = true })

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
    end,
  },
  {
    "lewis6991/whatthejump.nvim",
    -- enabled = false,
    keys = { "<C-i>", "<C-o>" },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    enabled = false,
    ft = { "markdown", "codecompanion", "Avante" },
    opts = {
      render_modes = true,
      file_types = { "markdown", "Avante", "codecompanion", "rmd" },
      completions = { lsp = { enabled = true } },
      debounce = 200,
      code = {
        style = "language",
        highlight = nil,
        highlight_inline = nil,
      },
    },
  },
  {
    "ramilito/winbar.nvim",
    event = "BufAdd",
    opts = {
      -- your configuration comes here, for example:
      icons = true,
      filetype_exclude = {
        "vista",
        "dbui",
        "help",
        "startify",
        "dashboard",
        "packer",
        "neo-tree",
        "neogitstatus",
        "NvimTree",
        "Trouble",
        "alpha",
        "lir",
        "Outline",
        "spectre_panel",
        "toggleterm",
        "TelescopePrompt",
        "prompt",
        "httpResult",
        "rest_nvim_result",
        "netrw",
        "kulala_ui",
        "AvanteInput",
        "AvanteSelectedFiles",
        "Avante",
        "better_term",
        "oil",
        "DiffviewFiles",
      },
      background_color = "DiagnosticHint",
      diagnostics = true,
      buf_modified = true,
      dir_levels = 2,
      -- buf_modified_symbol = "M",
      -- or use an icon
      buf_modified_symbol = "●",
      dim_inactive = {
        enabled = true,
        highlight = "WinbarNC",
        icons = true, -- whether to dim the icons
        name = true, -- whether to dim the name
      },
      exclude_if = function()
        return vim.b.no_winbar == true
      end,
    },
  },
}
