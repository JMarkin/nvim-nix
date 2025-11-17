{
  description = "Neovim derivation";

  nixConfig = {
    extra-substituters = [
      "http://tln.jmarkin.ru:8501"
    ];
    extra-trusted-public-keys = [
      "tln.jmarkin.ru:EOj0yG2nmqNFVZA1GWYKZ8JU8uZHbAzvYXglA8u+yKw="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    neovim-nightly-overlay.inputs.nixpkgs.follows = "nixpkgs";
    neovim-nightly-overlay.inputs.flake-parts.follows = "flake-parts";

    flake-parts.url = "github:hercules-ci/flake-parts";
    gen-luarc.url = "github:mrcjkb/nix-gen-luarc-json";
    gen-luarc.inputs.nixpkgs.follows = "nixpkgs";
    gen-luarc.inputs.flake-parts.follows = "flake-parts";


    blink-pairs.url = "github:Saghen/blink.pairs?ref=574ce24d44526a76e0b76e921a92c6737a6b3954";

    # kulala-nvim ecosystem
    kulala-nvim.url = "github:mistweaverco/kulala.nvim";
    kulala-nvim.flake = false;
    kulala-fmt.url = "github:mistweaverco/kulala-fmt";
    kulala-fmt.inputs.flake-parts.follows = "flake-parts";
    kulala-fmt.inputs.nixpkgs.follows = "nixpkgs";

    # Add bleeding-edge plugins here.
    # They can be updated with `nix flake update` (make sure to commit the generated flake.lock)

    smart-splits-nvim = {
      url = "github:mrjones2014/smart-splits.nvim";
      flake = false;
    };

    oil-nvim = {
      url = "github:stevearc/oil.nvim";
      flake = false;
    };
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

    # beacon-nvim = {
    #   url = "github:DanilaMihailov/beacon.nvim";
    #   flake = false;
    # };

    stay-in-place-nvim = {
      url = "github:gbprod/stay-in-place.nvim";
      flake = false;
    };

    namu-nvim = {
      url = "github:bassamsdata/namu.nvim";
      flake = false;
    };

    nvim-window = {
      url = "github:yorickpeterse/nvim-window";
      flake = false;
    };

    gp-nvim = {
      url = "github:Robitx/gp.nvim";
      flake = false;
    };

    # my

    cmp-diag-codes = {
      url = "github:JMarkin/cmp-diag-codes";
      flake = false;
    };
    # diaglist-nvim = {
    #   url = "github:JMarkin/diaglist.nvim";
    #   flake = false;
    # };
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
