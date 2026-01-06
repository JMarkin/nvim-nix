{ pkgs, ... }:
{

  packages = with pkgs; [
    rust-analyzer
    cargo

    graphviz
    lldb

    cargo-nextest
  ];

  luasetup = /*lua*/''
    vim.lsp.enable("rust_analyzer", vim.g.lsp_autostart)
  '';

  plugins = with pkgs.vimPlugins;[
    {
      plugin = rustaceanvim.overrideAttrs (oa: {
        # neotest error
        doCheck = false;
      });
      optional = false;
    }
  ];

}
