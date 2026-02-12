{ pkgs, ... }:
{
  plugins = with pkgs.vimPlugins; [
    {
      plugin = nvim-aider;
      type = "lua";
      optional = true;
      config = /*lua*/''
        lze.load {
          "${nvim-aider.pname}",
          cmd = "Aider",
          -- Example key mappings for common actions:
          keys = {
            { "<leader>a/", "<cmd>Aider toggle<cr>", desc = "Toggle Aider" },
            { "<leader>as", "<cmd>Aider send<cr>", desc = "Send to Aider", mode = { "n", "v" } },
            { "<leader>ac", "<cmd>Aider command<cr>", desc = "Aider Commands" },
            { "<leader>ab", "<cmd>Aider buffer<cr>", desc = "Send Buffer" },
            { "<leader>a+", "<cmd>Aider add<cr>", desc = "Add File" },
            { "<leader>a-", "<cmd>Aider drop<cr>", desc = "Drop File" },
            { "<leader>ar", "<cmd>Aider add readonly<cr>", desc = "Add Read-Only" },
            { "<leader>aR", "<cmd>Aider reset<cr>", desc = "Reset Session" },
            -- Example nvim-tree.lua integration if needed
            { "<leader>a+", "<cmd>AiderTreeAddFile<cr>", desc = "Add File from Tree to Aider", ft = "NvimTree" },
            { "<leader>a-", "<cmd>AiderTreeDropFile<cr>", desc = "Drop File from Tree from Aider", ft = "NvimTree" },
          },
          after = function()
            require("nvim_aider").setup({
                args = {
                  "--no-auto-commits",
                  "--pretty",
                  "--stream",
                  "--watch-files",
                  "--no-show-model-warnings",
                  "--no-verify-ssl",
                  "--analytics-disable",
                  "--thinking-tokens 1024",
                  "--cache-prompt",
                },
                theme = {
                  user_input_color = "#8fb573",           -- Bamboo green (matches 'green' in palette)
                  tool_output_color = "#70a5eb",          -- Bamboo blue (matches 'blue')
                  tool_error_color = "#e75a7c",           -- Bamboo red (matches 'red')
                  tool_warning_color = "#dbb671",         -- Bamboo yellow (matches 'yellow')
                  assistant_output_color = "#a084c3",     -- Bamboo purple (matches 'purple')
                  completion_menu_color = "#f1f1f1",      -- Foreground (matches 'fg')
                  completion_menu_bg_color = "#252623",   -- Background (matches 'bg0')
                  completion_menu_current_color = "#252623", -- Current item text (bg0)
                  completion_menu_current_bg_color = "#8fb573", -- Current item highlight (green)
                },
            })
          end,
        }
      '';
    }
  ];

  packages = with pkgs; [
    aider-chat
  ];
}

