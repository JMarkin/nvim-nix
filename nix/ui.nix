{ inputs, pkgs, mkNvimPlugin, ... }:
let
  beacon-nvim = (mkNvimPlugin inputs.beacon-nvim "beacon.nvim");
in
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
  (mkNvimPlugin inputs.local-highlight-nvim "local-highlight.nvim")
  (mkNvimPlugin inputs.whatthejump-nvim "whatthejump.nvim")
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
  {
    plugin = beacon-nvim;
    optional = true;
    type = "lua";
    config = /*lua*/''
      if not vim.g.neovide then
      lze.load({
        "${beacon-nvim.pname}",
        after =  function()
          require("beacon").setup {
              enabled = function()
                local line_count = vim.api.nvim_buf_line_count(vim.api.nvim_get_current_buf())
                if line_count > 1000 then
                  return false
                end
                return true
              end, --- (boolean | fun():boolean) check if enabled
              speed = 2, --- integer speed at wich animation goes
              width = 20, --- integer width of the beacon window
              winblend = 70, --- integer starting transparency of beacon window :h winblend
              fps = 60, --- integer how smooth the animation going to be
              min_jump = 10, --- integer what is considered a jump. Number of lines
              cursor_events = { "CursorMoved" }, -- table<string> what events trigger check for cursor moves
              window_events = { "WinEnter", "FocusGained" }, -- table<string> what events trigger cursor highlight
              highlight = { bg = "white", ctermbg = 15 }, -- vim.api.keyset.highlight table passed to vim.api.nvim_set_hl
            }
          end,
        event = { "BufAdd" },
      })
      end
    '';
  }

]
