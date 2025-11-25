{ inputs, pkgs, mkNvimPlugin, ... }:
with pkgs.vimPlugins; [
  {
    plugin = sidekick-nvim.overrideAttrs (oa: {
      runtimeDeps = [
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
              mux = {
                backend = "tmux",
                enabled = true,
              },
              picker = "fzf-lua",

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
            "<c-.>",
            function() require("sidekick.cli").toggle({name="crush"}) end,
            desc = "Sidekick Toggle",
            mode = { "n", "t", "i", "x" },
          },
          {
            "<leader>aa",
            function() require("sidekick.cli").toggle({name="crush"}) end,
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
