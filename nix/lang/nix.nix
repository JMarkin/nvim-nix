{ pkgs, ... }:
{

  packages = with pkgs; [
    nixd
    nixpkgs-fmt
  ];

  luasetup = /*lua*/''
    vim.lsp.enable("nixd", vim.g.lsp_autostart)
  '';

  plugins = [];
}
