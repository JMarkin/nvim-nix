if vim.g.did_load_blink_plugin then
  return
end
vim.g.did_load_blink_plugin = true

local funcs = require("funcs")
local lf = require("largefiles")

lze.load({
  "neogen",
  on_require = "neogen",
  after = function()
    require("neogen").setup({
      enabled = true,
      input_after_comment = true,
      snippet_engine = "nvim",
    })
  end,
  cmd = "Neogen",
  keys = {
    {
      "<leader>lD",
      "<cmd>Neogen<cr>",
      desc = "Lang: generate docs",
    },
  },
})

lze.load({
  { "friendly-snippets", on_plugin = "blink.cmp" },
  { "colorful-menu.nvim", on_plugin = "blink.cmp" },
  { "cmp-diag-codes", on_plugin = "blink.cmp" },
  { "cmp-nvim-tags", on_plugin = "blink.cmp" },

  -- cmp compact
  {
    "blink.compat",
    on_plugin = "blink.cmp",
    after = function()
      require("blink.compat").setup({ impersonate_nvim_cmp = true })
    end,
  },
})

lze.load({
  "blink.cmp",
  event = { "InsertEnter", "CmdlineEnter" },
  after = function()
    local blink = require("blink-cmp")
    local opts = {
      cmdline = {
        enabled = true,
        completion = { menu = { auto_show = false } },
        keymap = {
          ["<CR>"] = { "accept_and_enter", "fallback" },
        },
      },
      keymap = {
        preset = "default",
        ["<C-a>"] = { "hide" },
        ["<C-k>"] = { "show_documentation", "hide_documentation" },

        ["<C-e>"] = { "scroll_documentation_up", "fallback" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },
        ["<c-b>"] = {},

        ["<c-x><c-f>"] = {
          function()
            blink.show({ providers = { "path" } })
          end,
        },
        ["<c-x><c-]>"] = {
          function()
            blink.show({ providers = { "tags" } })
          end,
        },
        ["<c-x><c-o>"] = {
          function()
            blink.show({ providers = { "lsp" } })
          end,
        },
      },
      completion = {
        keyword = { range = "full" },
        accept = {
          dot_repeat = false,
        },
        ghost_text = {
          enabled = true,
        },
        trigger = {
          show_in_snippet = true,
          show_on_keyword = true,
          show_on_trigger_character = true,
          show_on_insert_on_trigger_character = true,
          show_on_accept_on_trigger_character = true,
        },
        list = {
          selection = {
            preselect = false,
            auto_insert = true,
          },
        },
      },

      sources = {
        default = function(ctx)
          if lf.is_large_file(vim.api.nvim_get_current_buf(), true) then
            return { "tags", "omni" }
          elseif funcs.in_treesitter_capture("comment") or funcs.in_syntax_group("Comment") then
            return { "diag-codes", "buffer", "snippets", "lsp" }
          end
          return { "lsp", "buffer", "snippets" }
        end,
        per_filetype = {
          sql = { "dadbod", "buffer", "snippets" },
          lua = { inherit_defaults = true, "lazydev" },
          codecompanion = { inherit_defaults = true, "codecompanion" },
          AvanteInput = { inherit_defaults = true, "avante" },
        },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 100,
          },
          dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
          tags = {
            name = "tags",
            module = "blink.compat.source",
            score_offset = -2,
            opts = {
              exact_match = true,
              current_buffer_only = false,
            },
          },
          ["diag-codes"] = {
            name = "diag-codes",
            module = "blink.compat.source",
            score_offset = 100,
            opts = {
              in_comment = false,
            },
          },
        },
      },
      fuzzy = {
        prebuilt_binaries = {
          download = false,
        },
      },
    }
    opts.completion.menu = {
      draw = {
        -- We don't need label_description now because label and label_description are already
        -- conbined together in label by colorful-menu.nvim.
        columns = { { "kind_icon" }, { "label", gap = 1 }, { "source_name" } },
        components = {
          label = {
            width = { fill = true, max = 60 },
            text = function(ctx)
              local highlights_info = require("colorful-menu").blink_highlights(ctx)
              if highlights_info ~= nil then
                return highlights_info.label
              else
                return ctx.label
              end
            end,
            highlight = function(ctx)
              local highlights = {}
              local highlights_info = require("colorful-menu").blink_highlights(ctx)
              if highlights_info ~= nil then
                highlights = highlights_info.highlights
              end
              for _, idx in ipairs(ctx.label_matched_indices) do
                table.insert(highlights, { idx, idx + 1, group = "BlinkCmpLabelMatch" })
              end
              -- Do something else
              return highlights
            end,
          },
        },
      },
    }

    local ok, _ = pcall(require, "minuet")
    if ok then
      opts.keymap["<c-x><c-z>"] = require("minuet").make_blink_map()

      opts.sources.providers.minuet = {
        name = "minuet",
        module = "minuet.blink",
        async = true,
        -- Should match minuet.config.request_timeout * 1000,
        -- since minuet.config.request_timeout is in seconds
        timeout_ms = 3000,
        score_offset = 50, -- Gives minuet higher priority among suggestions
      }
    end

    ok, _ = pcall(require, "blink-cmp-avante")
    if ok then
      opts.sources.providers.avante = {
        module = "blink-cmp-avante",
        name = "Avante",
        opts = {
          -- options for blink-cmp-avante
        },
      }
    end

    blink.setup(opts)
  end,
})
