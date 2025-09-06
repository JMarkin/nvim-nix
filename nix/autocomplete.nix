{ inputs, pkgs, mkNvimPlugin, lib, ... }:
let

  version = "2025-08-28";

  src = pkgs.fetchFromGitHub {
    owner = "Saghen";
    repo = "blink.pairs";
    rev = "3cf0b660caf266992d6c62eb1f6049c483b35409";
    hash = "sha256-pE5HxryAfpMLRSRddr9kqhpI9hTnHZL/qgtHU53gt6k=";
  };


  rustPlatform = pkgs.makeRustPlatform {
    cargo = pkgs.rust-bin.nightly."2025-04-12".minimal;
    rustc = pkgs.rust-bin.nightly."2025-04-12".minimal;
  };

  blink-pairs-lib = rustPlatform.buildRustPackage {
    pname = "blink-pairs";
    inherit version src;

    cargoHash = "sha256-Cn9zRsQkBwaKbBD/JEpFMBOF6CBZTDx7fQa6Aoic4YU=";

    doCheck = false;
    nativeBuildInputs = [
      pkgs.pkg-config
    ];
  };
  blink-pairs = pkgs.vimUtils.buildVimPlugin {
    pname = "blink.pairs";
    inherit version src;

    preInstall =
      let
        ext = pkgs.stdenv.hostPlatform.extensions.sharedLibrary;
      in
      ''
        mkdir -p target/release
        ln -s ${blink-pairs-lib}/lib/libblink_pairs${ext} target/release/
      '';

    passthru = {
      updateScript = pkgs.nix-update-script {
        attrPath = "vimPlugins.blink-pairs.blink-pairs-lib";
      };

      # needed for the update script
      inherit blink-pairs-lib;
    };

    meta = {
      description = "Rainbow highlighting and intelligent auto-pairs for Neovim";
      homepage = "https://github.com/Saghen/blink.pairs";
      changelog = "https://github.com/Saghen/blink.pairs/blob/${src.tag}/CHANGELOG.md";
      license = lib.licenses.mit;
    };
  };
in
with pkgs.vimPlugins; [
  blink-cmp
  blink-pairs
  friendly-snippets
  lazydev-nvim
  neogen
  colorful-menu-nvim
  blink-compat
  cmp-nvim-tags
  (mkNvimPlugin inputs.cmp-diag-codes "cmp-diag-codes")

]
