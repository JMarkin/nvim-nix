{ pkgs, inputs, ... }:
let
  system = pkgs.system;
  # bacon-flake = inputs.bacon.defaultPackage.${system};
  # bacon-ls = inputs.bacon-ls.defaultPackage.${system};
in
{

  packages = with pkgs; [
    rust-analyzer
    # bacon-flake
    # bacon-ls
    cargo
    rustc
    rustfmt

    graphviz
    lldb

    cargo-nextest
  ];

  luasetup = /*lua*/''
    vim.lsp.config('rust_analyzer', {
      settings = {
        ["rust-analyzer"] = {
          diagnostics = {
            enable = true,
          },
          checkOnSave = {
            enable = true,
          },
          completion = {
            autoimport = {
              enable = true,
            },
          },
          procMacro = {
            enable = true,
          },
        },
      }
    }, vim.g.lsp_autostart)
    
    -- vim.lsp.config('bacon_ls', vim.g.lsp_autostart)
  '';

  plugins = with pkgs.vimPlugins;[
    # {
    #   plugin = rustaceanvim.overrideAttrs (oa: {
    #     # neotest error
    #     doCheck = false;
    #   });
    #   optional = false;
    # }
  ];

}
