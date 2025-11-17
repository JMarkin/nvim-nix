{ pkgs, ... }:
{

  packages = with pkgs; [
    vscode-langservers-extracted
    biome
    prettierd
    nodejs
    bun
    yarn-berry
    typescript-language-server
    vtsls
    typescript
  ];

  plugins = with pkgs.vimPlugins; [
    {
      plugin = nvim-vtsls;
      type = "lua";
      optional = true;
      config = /*lua*/''
        lze.load {
            "${nvim-vtsls.pname}",
            ft={
              "javascript",
              "javascriptreact",
              "javascript.jsx",
              "typescript",
              "typescriptreact",
              "typescript.tsx",
            }
          }
      '';
    }
  ];
}
