{ inputs, pkgs, mkNvimPlugin, ... }:
with pkgs.vimPlugins; [
  {
    plugin = nui-nvim;
    optional = true;
    type = "lua";
    config = /*lua*/''
      lze.load {
        "${nui-nvim.pname}",
        on_require="nui",
      }
    '';
  }
  {
    plugin = smartyank-nvim;
    optional = true;
    type = "lua";
    config = /*lua*/''
      lze.load {
        "${smartyank-nvim.pname}",
        event = "ModeChanged",
        after = function()
          require("smartyank").setup({
            highlight = {
              enabled = true, -- highlight yanked text
              timeout = 100,
            },
          })
          vim.api.nvim_create_autocmd("FocusGained", {
            callback = function()
              local loaded_content = vim.fn.getreg("+")
              if loaded_content ~= "" then
                vim.fn.setreg('"', loaded_content)
              end
            end,
          })
        end
      }
    '';
  }
  {
    plugin = (mkNvimPlugin inputs.local-highlight-nvim "local-highlight.nvim");
    optional = true;
    type = "lua";
    config = /*lua*/''
      lze.load({
         "local-highlight.nvim",
         on_require="local-highlight",
         after = function()
          vim.api.nvim_set_hl(0, "LocalHighlight", { underline = true })
          require("local-highlight").setup({
            insert_mode = false,
            file_types = {},
            hlgroup = "LocalHighlight",
          })
         end,
      })
    '';
  }
  {
    plugin = (mkNvimPlugin inputs.whatthejump-nvim "whatthejump.nvim");
    optional = true;
    type = "lua";
    config = /*lua*/''
      lze.load({
        "whatthejump.nvim",
        keys = { "<C-i>", "<C-o>" },
      })
    '';
  }

  {
    plugin = render-markdown-nvim;
    optional = true;
    type = "lua";
    config = /*lua*/''
      lze.load({
        "${render-markdown-nvim.pname}",
        ft = { "markdown", "codecompanion", "Avante" },
        after = function()
          require("render-markdown").setup{
            render_modes = true,
            file_types = { "markdown", "Avante", "codecompanion", "rmd" },
            completions = { lsp = { enabled = true } },
            debounce = 200,
            code = {
              style = "language",
              highlight = nil,
              highlight_inline = nil,
            },
          }
        end
      })
    '';
  }

  {
    plugin = winbar-nvim;
    optional = true;
    type = "lua";
    config = /*lua*/''
      lze.load({
        "${winbar-nvim.pname}",
        event = "BufAdd",
        after = function()
          require("winbar").setup{
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
          }
        end
      })
    '';
  }
]
