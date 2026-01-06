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

  luasetup = /*lua*/''
    vim.lsp.enable("biome", vim.g.lsp_autostart)
    vim.lsp.enable("vtsls", vim.g.lsp_autostart)
  '';
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
