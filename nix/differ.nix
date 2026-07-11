{ pkgs
, inputs
, ...
}:
let
  differ-sidecar = pkgs.buildGoModule {
    pname = "differ-sidecar";
    version = inputs.differ-nvim.lastModifiedDate;
    src = inputs.differ-nvim;
    subPackages = [ "cmd/differ-sidecar" ];
    vendorHash = null;
    doCheck = false;
    postPatch = ''
      sed -i 's/go 1.26.4/go 1.26.3/' go.mod
    '';
  };

  differ-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "differ.nvim";
    version = inputs.differ-nvim.lastModifiedDate;
    src = inputs.differ-nvim;
    preInstall = ''
      mkdir -p bin
      ln -s ${differ-sidecar}/bin/differ-sidecar bin/differ-sidecar
    '';
  };
in
[
  {
    plugin = differ-nvim;
    optional = true;
    config = /*lua*/''
      lze.load {
        "${differ-nvim.pname}",
        cmd = { "Differ" },
        after = function()
          require("differ").setup({
            command_alias = "D",
          })
        end,
      }
    '';
  }
]
