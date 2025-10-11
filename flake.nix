{
  description = "Neovim derivation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    neovim-nightly-overlay.inputs.nixpkgs.follows = "nixpkgs";
    neovim-nightly-overlay.inputs.flake-parts.follows = "flake-parts";

    flake-parts.url = "github:hercules-ci/flake-parts";
    gen-luarc.url = "github:mrcjkb/nix-gen-luarc-json";
    gen-luarc.inputs.nixpkgs.follows = "nixpkgs";
    gen-luarc.inputs.flake-parts.follows = "flake-parts";


    blink-pairs.url = "github:Saghen/blink.pairs";

    # Add bleeding-edge plugins here.
    # They can be updated with `nix flake update` (make sure to commit the generated flake.lock)
    hlargs-nvim = {
      url = "github:m-demare/hlargs.nvim";
      flake = false;
    };
    nvim-yati = {
      url = "github:yioneko/nvim-yati";
      flake = false;
    };
    yaml-nvim = {
      url = "github:cuducos/yaml.nvim";
      flake = false;
    };
    local-highlight-nvim = {
      url = "github:tzachar/local-highlight.nvim";
      flake = false;
    };

    whatthejump-nvim = {
      url = "github:lewis6991/whatthejump.nvim";
      flake = false;
    };

    beacon-nvim = {
      url = "github:DanilaMihailov/beacon.nvim";
      flake = false;
    };

    stay-in-place-nvim = {
      url = "github:gbprod/stay-in-place.nvim";
      flake = false;
    };

    namu-nvim = {
      url = "github:bassamsdata/namu.nvim";
      flake = false;
    };

    cmp-diag-codes = {
      url = "github:JMarkin/cmp-diag-codes";
      flake = false;
    };
    diaglist-nvim = {
      url = "github:JMarkin/diaglist.nvim";
      flake = false;
    };
    gentags-lua = {
      url = "github:JMarkin/gentags.lua?ref=feat/neovim-0.10";
      flake = false;
    };
  };
  outputs = inputs@{ flake-parts, ... }:
    let
      # This is where the Neovim derivation is built.
      neovim-overlay = import ./nix/neovim-overlay.nix {
        inherit inputs;
      };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { system, pkgs, ... }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              # Import the overlay, so that the final Neovim derivation(s) can be accessed via pkgs.<nvim-pkg>
              neovim-overlay
              # This adds a function can be used to generate a .luarc.json
              # containing the Neovim API all plugins in the workspace directory.
              # The generated file can be symlinked in the devShell's shellHook.
              inputs.gen-luarc.overlays.default
            ];
            config = { };
          };
          packages = rec {
            nvim = pkgs.nvim-pkg;
            nvim-small = pkgs.nvim-small;
            nvim-minimal = pkgs.nvim-minimal;
            default = nvim;
          };
          devShells = {
            default = pkgs.mkShell {
              name = "nvim-devShell";
              buildInputs = with pkgs; [
                # Tools for Lua and Nix development, useful for editing files in this repo
                lua-language-server
                nixd
                stylua
                luajitPackages.luacheck
                nvim-dev
              ];
              shellHook = ''
                # symlink the .luarc.json generated in the overlay
                ln -fs ${pkgs.nvim-luarc-json} .luarc.json
                # allow quick iteration of lua configs
                ln -Tfns $PWD/nvim ~/.config/nvim-dev
              '';
            };
          };
        };
      flake.overlays.default = neovim-overlay;
    };
}
