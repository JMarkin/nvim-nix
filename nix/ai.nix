{ inputs, pkgs, mkNvimPlugin, ... }:
with pkgs.vimPlugins; [
  # {
  #   plugin = agentic-nvim;
  #   type = "lua";
  #   optional = true;
  #   config = /*lua*/''
  #     lze.load {
  #       "${agentic-nvim.pname}",
  #       after = function()
  #         require("agentic").setup({
  #           provider = "opencode-acp",
  #         })
  #       end,
  #       on_require = {"agentic"},
  #       keys = {
  #         {
  #           "<leader>aa", function() require("agentic").toggle() end,
  #           mode = { "n", "v", "i" },
  #           desc = "Toggle Agentic Chat"
  #         },
  #         {
  #           "<leader>ad",
  #           function() require("agentic").add_selection_or_file_to_context() end,
  #           mode = { "n", "v" },
  #           desc = "Add file or selection to Agentic to Context"
  #         },
  #         {
  #           "<leader>an",
  #           function() require("agentic").new_session() end,
  #           mode = { "n", "v", "i" },
  #           desc = "New Agentic Session"
  #         },
  #       },
  #     }
  #   '';
  # }
  {
    plugin = sidekick-nvim.overrideAttrs (oa: {
      runtimeDeps = [
        nvim-treesitter-textobjects
      ];
    });
    type = "lua";
    optional = true;
    config = /*lua*/''
      lze.load {
        "${sidekick-nvim.pname}",
        cmd = {"Sidekick"},
        after = function() 
          require("sidekick").setup {
            nes = { enabled = false },
            cli = {
              picker = "fzf-lua",
              mux = {
                backend = "tmux",
                enabled = true,
                create =  "window",
              },

              tools = {
                opencode = {
                  cmd = { "opencode" },
                  -- HACK: https://github.com/sst/opencode/issues/445
                  env = { 
                    OPENCODE_THEME = "system",
                    OPENROUTER_API_KEY = vim.env.OPENROUTER_API_KEY,
                  },
                }
              },

              --- CLI Tool Keymaps (default mode is `t`)
              ---@type table<string, sidekick.cli.Keymap|false>
              keys = {
                buffers       = { "<c-b>", "buffers"   , mode = "nt", desc = "open buffer picker" },
                files         = { "<c-f>", "files"     , mode = "nt", desc = "open file picker" },
                hide_ctrl_q   = { "<A-q>", "hide"      , mode = "n" , desc = "hide the terminal window" },
                hide_ctrl_dot = { "<c-.>", "hide"      , mode = "nt", desc = "hide the terminal window" },
                prompt        = { "<c-p>", "prompt"    , mode = "t" , desc = "insert prompt or context" },
              },
            },
          }
        end,
        keys = {
          {
            "<leader>aa",
            function() require("sidekick.cli").toggle({name="opencode"}) end,
            desc = "Sidekick Toggle CLI",
          },
          {
            "<leader>as",
            function() require("sidekick.cli").select({ filter = { installed = true } }) end,
            desc = "Select CLI",
          },
          {
            "<leader>ad",
            function() require("sidekick.cli").close() end,
            desc = "Detach a CLI Session",
          },
          {
            "<leader>at",
            function() require("sidekick.cli").send({ msg = "{this}" }) end,
            mode = { "x", "n" },
            desc = "Send This",
          },
          {
            "<leader>af",
            function() require("sidekick.cli").send({ msg = "{file}" }) end,
            desc = "Send File",
          },
          {
            "<leader>av",
            function() require("sidekick.cli").send({ msg = "{selection}" }) end,
            mode = { "x" },
            desc = "Send Visual Selection",
          },
          {
            "<leader>ap",
            function() require("sidekick.cli").prompt() end,
            mode = { "n", "x" },
            desc = "Sidekick Select Prompt",
          },
        },
      }
    '';
  }
]
