{
  description = "Nix-flaked Neovim configuration with extensive plugin management and AI tooling integration";


  nixConfig = {
    extra-substituters = [
      "https://nixcache.jmarkin.ru"
    ];
    extra-trusted-public-keys = [
      "nixcache.jmarkin.ru:EM46eZT5GshZQEZHKtFZa3f/KTnxh2bdU/TSuwkAtQ0="
    ];
  };


  inputs = {
    # Core Nix infrastructure
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    gen-luarc.url = "github:mrcjkb/nix-gen-luarc-json";
    gen-luarc.inputs.nixpkgs.follows = "nixpkgs";
    gen-luarc.inputs.flake-parts.follows = "flake-parts";

    # Theme and UI dependencies
    blink-pairs.url = "github:Saghen/blink.pairs?ref=574ce24d44526a76e0b76e921a92c6737a6b3954";

    # Development and formatting tools
    kulala-nvim.url = "github:mistweaverco/kulala.nvim";
    kulala-nvim.flake = false;
    kulala-fmt.url = "github:mistweaverco/kulala-fmt";
    kulala-fmt.inputs.flake-parts.follows = "flake-parts";
    kulala-fmt.inputs.nixpkgs.follows = "nixpkgs";


    nvim-treesitter-main.url = "github:iofq/nvim-treesitter-main";
    nvim-treesitter-main.inputs.nixpkgs.follows = "nixpkgs";

    # Bleeding-edge Neovim plugins
    # These can be updated with `nix flake update` (remember to commit flake.lock)

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

    # gp-nvim = {
    #   url = "github:Robitx/gp.nvim";
    #   flake = false;
    # };

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
      # Supported systems - add more as needed
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { system, pkgs, ... }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              inputs.nvim-treesitter-main.overlays.default
              # Import the overlay, so that the final Neovim derivation(s) can be accessed via pkgs.<nvim-pkg>
              neovim-overlay
              # This adds a function can be used to generate a .luarc.json
              # containing the Neovim API all plugins in the workspace directory.
              # The generated file can be symlinked in the devShell's shellHook.
              inputs.gen-luarc.overlays.default
            ];
            config = { };
          };
          packages =
            rec {
              nvim = pkgs.nvim-pkg;
              nvim-small = pkgs.nvim-small;
              nvim-minimal = pkgs.nvim-minimal;
              default = nvim;
              bench-nvim = pkgs.writeShellScriptBin "bench-nvim" ''
                ${pkgs.hyperfine}/bin/hyperfine --warmup 4 '${pkgs.nvim-pkg}/bin/nvim -c ":q"'
              '';
              bench-nvim-small = pkgs.writeShellScriptBin "bench-nvim-small" ''
                ${pkgs.hyperfine}/bin/hyperfine --warmup 4 '${pkgs.nvim-small}/bin/nvim -c ":q"'
              '';
              bench-nvim-minimal = pkgs.writeShellScriptBin "bench-nvim-minimal" ''
                ${pkgs.hyperfine}/bin/hyperfine --warmup 4 '${pkgs.nvim-minimal}/bin/nvim -c ":q"'
              '';

              # Development tools and language-specific packages
              codingPackages = pkgs.codingPackages;
            };
          devShells = {
            default = pkgs.mkShell {
              name = "nvim-devShell";
              buildInputs = with pkgs; [
                # Essential development tools for maintaining this flake
                lua-language-server # Lua language server for config development
                nixd # Nix language server
                stylua # Lua code formatter
                luajitPackages.luacheck # Lua linter
                nvim-dev # Development version of Neovim
              ];
              shellHook = ''
                # Symlink generated .luarc.json for IDE support
                ln -fs ${pkgs.nvim-luarc-json} .luarc.json
                
                # Link configuration for development testing
                # This allows testing changes with: nvim -u ~/.config/nvim-dev/init.lua
                ln -Tfns $PWD/nvim ~/.config/nvim-dev

                echo "Test with: nvim -u ~/.config/nvim-dev/init.lua"
              '';
            };
          };
        };
      flake.overlays.default = neovim-overlay;
    };
}
