{ pkgs, mkNvimPlugin, lib, inputs, ... }:
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
  http = callPackage ./http.nix;
  js = callPackage ./js.nix;

  langs = [ unsorted go lua rust nix sql python http js ];

  setup = lib.strings.concatMapStrings (x: x.luasetup) langs;
in
{
  packages = [ pkgs.lspmux ] ++ builtins.concatMap (x: x.packages) langs;
  plugins = with pkgs.vimPlugins; [
    {
      plugin = nvim-lspconfig;
      optional = false;
      config = /*lua*/''
        ${setup}
      '';
    }
    {
      plugin = symbol-usage-nvim;
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
  ] ++ builtins.concatMap (x: x.plugins) langs;
}
