{ inputs, pkgs, mkNvimPlugin, ... }:
let
  src = inputs.cursortab-nvim;

  cursortab = pkgs.buildGo124Module {
    pname = "cursortab";
    version = src.shortRev or src.dirtyShortRev or "dirty";
    src = "${src}/server";
    vendorHash = "sha256-cTYS8PVnA/6d1VDxcqfSCENhCNj7hIKBhwwmku927qI=";
  };

in
{
  packages = [ cursortab ];
  plugins = with pkgs.vimPlugins; [ {
    plugin = cursortab-nvim;
    type = "lua";
    optional = true;
    config = /*lua*/ ''
      lze.load{
        "${cursortab-nvim.pname}",
        event=vim.g.post_load_events,
        after = function()
          require("cursortab").setup({
            runtime = {
              binary_path = "${cursortab}/bin/cursortab",
              socket_path = "/tmp/cursortab.socket",
              pid_path = "/tmp/cursortab.pid",
              log_path = "/tmp/cursortab.log",
            },
            provider = {
              type = "sweep",
              url = "/tmp/llama.sock",
              model = "sweep-next-edit-1.5b",
            },
          })
        end
      }
      '';
  }];
}
