{ inputs, pkgs, mkNvimPlugin, ... }:
{
  plugins = with pkgs.vimPlugins; [
    {
      plugin = llama-vim;
      type = "vim";
      optional = false;
      config = /*lua*/''
        vim.g.llama_config = {
          endpoint_fim='http://127.0.0.1:8012/infill',
          endpoint_inst='http://127.0.0.1:8012/v1/chat/completions',
          enable_at_startup = true,
          keymap_fim_trigger = "<c-f>",
          keymap_fim_accept_word = "<c-b>",

          keymap_inst_trigger  = "<c-i>",
          keymap_inst_retry    = "<c-o>",
          keymap_inst_continue = "<c-c>",
        }
      '';
    }
  ];

  packages = [
  ];
}

