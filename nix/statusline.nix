{ inputs, pkgs, mkNvimPlugin, ... }:
with pkgs.vimPlugins; [
  {
    plugin = mini-statusline;
    optional = true;
    config = /*lua*/''
      lze.load {
        "mini.statusline",
        event = vim.g.post_load_events,
        after = function()

          local active = function()
            local check_macro_recording = function()
              if vim.fn.reg_recording() ~= "" then
                return "Recording @" .. vim.fn.reg_recording()
              else
                return ""
              end
            end
            local wiremux = function()
              local wm, ok = pcall(require, "wiremux")
              if not ok then return "" end
              
              local info = require("wiremux").statusline.get_info()
              if info.count == 0 then return "" end
              local icon = info.last_used.kind == "window" and "󰖯" or "󰆍"
              return string.format("%s %d", icon, info.count)
            end

            local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
            local git           = MiniStatusline.section_git({ trunc_width = 40 })
            local diff          = MiniStatusline.section_diff({ trunc_width = 75 })
            local diagnostics   = MiniStatusline.section_diagnostics({ trunc_width = 75 })
            local lsp           = MiniStatusline.section_lsp({ trunc_width = 75 })
            local filename      = "%t"
            local fileinfo      = MiniStatusline.section_fileinfo({ trunc_width = 120 })
            local location      = MiniStatusline.section_location({ trunc_width = 75 })
            local search        = MiniStatusline.section_searchcount({ trunc_width = 75 })
            local macro = check_macro_recording()
            local root_dir = vim.fn.fnamemodify(vim.fn.getcwd(), '%')

            return MiniStatusline.combine_groups({
              { hl = mode_hl,                  strings = { mode } },
              { hl = 'MiniStatuslineDevinfo',  strings = { root_dir, git, diff, diagnostics, lsp } },
              '%<', -- Mark general truncate point
              { hl = 'MiniStatuslineFilename', strings = { filename } },
              '%=', -- End left alignment
              { hl = "MiniStatuslineDevinfo", strings = { wiremux } },
              { hl = "MiniStatuslineDevinfo", strings = { macro } },
              { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
              { hl = mode_hl,                  strings = { search, location } },
            })
          end
          require("mini.statusline").setup({
            content = {
              -- Content for active window
              active = active,
              -- Content for inactive window(s)
              inactive = nil,
            },
          })

          local fn = require("funcs")

          fn.augroup("disable statusline", {
            "FileType",
            {
              pattern = {'AgenticChat', 'AgenticInput', 'AgenticCode', 'AgenticFiles'},
              callback = function()
                vim.b.ministatusline_disable = true
              end,

            }
        })
        end,
      }
    '';
  }
]
