{ pkgs
, inputs
, ...
}:
let
  juan-logs = pkgs.rustPlatform.buildRustPackage
    {
      pname = "juan-logs";
      src = inputs.juan-logs-nvim;
      version = inputs.juan-logs-nvim.lastModifiedDate;
      cargoHash = "sha256-DlrFiJjE6wNLfMwpeI6iz32GxfOlTozKTTRT2LP88BQ=";
      postInstall = ''
        cp -r $src/* $out
      '';
    };
  juan-logs-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "juan-logs-nvim";
    src = inputs.juan-logs-nvim;
    version = inputs.juan-logs-nvim.lastModifiedDate;
    preInstall = ''
      mkdir -p target/release
      ln -s ${juan-logs}/lib/lib* target/release/
    '';
  };
in
[
  {
    plugin = juan-logs-nvim;
    type = "lua";
    optional = false;
    config = /*lua*/''
      require("juanlog").setup({
          threshold_size = 1024 * 1024 * 100, -- 100MB trigger
          mode = "dynamic", -- I don't remember the other mode name, but it's useless so don't worry
          lazy = true, -- background indexing. prevents neovim from freezing
          dynamic_chunk_size = 10000, -- lines to load at once
          dynamic_margin = 2000, -- trigger scroll load when this close to the edge
          patterns = { "*" },
          enable_custom_statuscol = true, -- fakes absolute line numbers
          syntax = false -- set to true to enable native vim syntax (can be slow)
      })
    '';
  }
]
