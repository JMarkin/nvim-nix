{ pkgs, ... }:

let
  gopls-proxy = pkgs.writeShellScriptBin "gopls-proxy" ''
    #!${pkgs.bash}/bin/bash
    exec ${pkgs.lspmux}/bin/lspmux client --server-path ${pkgs.gopls}/bin/gopls $@
  '';
in

{

  packages = with pkgs; [
    go
    golangci-lint
    gopls
    # gopls-proxy
    gotools
    delve
    mockgen

    gofumpt
    # golines
    # gomodifytags
    # iferr
    # impl
    # govulncheck
  ];

  plugins = [ ];

  luasetup = /*lua*/''
    vim.lsp.enable("gopls", vim.g.lsp_autostart)
    vim.lsp.enable("golangci_lint_ls", vim.g.lsp_autostart)
  '';
}
