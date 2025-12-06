{ inputs, pkgs, mkNvimPlugin, ... }:
with pkgs.vimPlugins; [
  {
    plugin = nui-nvim;
    optional = true;
    type = "lua";
    config = /*lua*/''
      lze.load {
        "${nui-nvim.pname}",
        on_require="nui",
      }
    '';
  }
  local-highlight-nvim
  whatthejump-nvim
  render-markdown-nvim
  dropbar-nvim

]
