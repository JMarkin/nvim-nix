{ pkgs, ... }:
{

  packages = with pkgs; [
    go
    golangci-lint
    gopls
    gotools
    delve
    mockgen

    # gofumpt
    # golines
    # gomodifytags
    # iferr
    # impl
    # govulncheck
  ];

  plugins = [ ];
}
