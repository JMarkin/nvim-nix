{ pkgs, mkNvimPlugin, inputs, ... }:
let
  callPackage = (file: pkgs.callPackage file {
    inherit inputs pkgs mkNvimPlugin;
  });
  unsorted = callPackage ./unsorted.nix;
  go = callPackage ./go.nix;
  lua = callPackage ./lua.nix;
  rust = callPackage ./rust.nix;
  nix = callPackage ./nix.nix;
  sql = callPackage ./sql.nix;
  python = callPackage ./python.nix;

  langs = [ unsorted go lua rust nix sql python ];
in
{
  packages = builtins.concatMap (x: x.packages) langs;
  plugins = with pkgs.vimPlugins; [
    {
      plugin = nvim-lspconfig;
      type = "lua";
      optional = true;
      config = /*lua*/''
        lze.load {
          "${nvim-lspconfig.pname}",
          event = vim.g.pre_load_events
        }
      '';
    }
    {
      plugin = symbol-usage-nvim;
      type = "lua";
      optional = true;
      config = /*lua*/''
        lze.load {
          "${symbol-usage-nvim.pname}",
          event="LspAttach",
          after=function()
            require('symbol-usage').setup({
                vt_position = 'end_of_line',
                references = { enabled = true, include_declaration = false },
                definition = { enabled = true },
                implementation = { enabled = true },
            })
          end
        }
      '';
    }
    {
      plugin = fidget-nvim;
      type = "lua";
      optional = true;
      config = /*lua*/''
        lze.load {
          "${fidget-nvim.pname}",
          event="LspAttach",
          after=function()
            require("fidget").setup({})
          end
        }
      '';
    }
  ] ++ builtins.concatMap (x: x.plugins) langs;
}
