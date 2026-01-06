{ pkgs, ... }:
{

  packages = with pkgs; [
    lua-language-server
    stylua
  ];

  luasetup = /*lua*/''
    vim.lsp.enable("lua_ls", vim.g.lsp_autostart)
  '';

  plugins = with pkgs.vimPlugins;[
    {
      plugin = lazydev-nvim;
      optional = true;
      type = "lua";
      config = /*lua*/''
        lze.load {
          "${lazydev-nvim.pname}",
          on_require = {"lazydev", "lazydev.integrations.blink"},
          ft= { "lua" }
        }
      '';
    }
  ];
}
