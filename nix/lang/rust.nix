{ pkgs, ... }:
{

  packages = with pkgs; [
    rust-analyzer
    cargo

    graphviz
    lldb
    ra-multiplex

    cargo-nextest
  ];


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
