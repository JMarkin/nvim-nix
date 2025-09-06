{ pkgs, ... }:
{

  packages = with pkgs; [
    go
    golangci-lint
    gopls
    gotools

    # gofumpt
    # golines
    # gomodifytags
    # iferr
    # impl
    # ginkgo
    # mockgen
    # govulncheck

  ];

  plugins = [ ];
}
