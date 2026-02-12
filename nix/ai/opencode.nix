{ inputs, pkgs, mkNvimPlugin, ... }:
{
  plugins = with pkgs.vimPlugins; [
    {
      plugin = opencode-nvim;
      type = "lua";
      optional = true;
      config = /*lua*/''
        lze.load {
          "${opencode-nvim.pname}",
          on_require = {"opencode", "opencode.ui.completion.engines.blink_cmp"},
          event=vim.g.post_load_events,
          cmd = {"Opencode"},
          after = function()
            require("opencode").setup({
              preferred_picker = "fzf-lua",
              preferred_completion = "blink",
              default_mode = 'plan',
              keymap_prefix = '<leader>a',
              quick_chat = {
                default_model = nil,
                instructions = nil,
              },
            })
          end,
        }
      '';
    }
  ];

  packages = with pkgs; [
    opencode
  ];
}

