{ pkgs, ... }:

let
  gopls-proxy = pkgs.writeShellScriptBin "gopls-proxy" ''
    #!${pkgs.bash}/bin/bash
    exec ${pkgs.lspmux}/bin/lspmux client --server-path ${pkgs.gopls}/bin/gopls $@
  '';
  gotoolsWithoutModernize = pkgs.symlinkJoin {
    name = "gotools-without-modernize";
    paths = [ pkgs.gotools ];
    postBuild = ''
      rm -f "$out/bin/modernize"
    '';
  };
in

{

  packages = with pkgs; [
    go
    golangci-lint
    gopls
    # gopls-proxy
    gotoolsWithoutModernize
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
