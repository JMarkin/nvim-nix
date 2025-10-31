{ pkgs, ... }:
{

  packages = with pkgs; [
    vscode-langservers-extracted
    biome
    nodejs
    bun
    yarn-berry
    typescript-language-server
    typescript
  ];

  plugins = with pkgs.vimPlugins; [
    {
      plugin = typescript-tools-nvim;
      type = "lua";
      optional = true;
      config = /*lua*/''
        lze.load {
            "${typescript-tools-nvim.pname}",
            event = vim.g.pre_load_events,
            after = function()
                require("typescript-tools").setup {
                  tsserver_path = "${pkgs.typescript}/bin/tsserver"
                }
            end
          }
      '';
    }
  ];
}
