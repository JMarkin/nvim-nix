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
]
