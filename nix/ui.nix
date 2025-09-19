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

  dropbar-nvim
]
