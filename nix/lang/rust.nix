{ pkgs, ... }:
{

  packages = with pkgs; [
    rust-analyzer
    cargo
    rustc
    rustfmt

    graphviz
    lldb

    cargo-nextest
  ];

  luasetup = /*lua*/''
    vim.g.rustaceanvim = {
      tools = {},
      server = {
        on_attach = function(client, bufnr) end,
        auto_attach = function(_)
          return vim.g.lsp_autostart
        end,
        default_settings = {
          ["rust-analyzer"] = {
            checkOnSave = true,
            completion = {
              autoimport = {
                enable = false,
              },
            },
            procMacro = {
              enable = true,
            },
            files = {
              excludeDirs = {
                ".direnv",
                "_build",
                ".dart_tool",
                ".flatpak-builder",
                ".git",
                ".gitlab",
                ".gitlab-ci",
                ".gradle",
                ".idea",
                ".next",
                ".project",
                ".scannerwork",
                ".settings",
                ".venv",
                "archetype-resources",
                "bin",
                "hooks",
                "node_modules",
                "po",
                "screenshots",
                "target",
              },
            },
          },
        },
      },
      -- DAP configuration
      dap = {},
    }
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
