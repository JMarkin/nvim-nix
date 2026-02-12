{
  description = "Nix-flaked Neovim configuration with extensive plugin management and AI tooling integration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";


    gen-luarc.url = "github:mrcjkb/nix-gen-luarc-json";
    gen-luarc.inputs.nixpkgs.follows = "nixpkgs";
    gen-luarc.inputs.flake-parts.follows = "flake-parts";

    blink-pairs.url = "github:Saghen/blink.pairs?ref=v0.4.1";
    kubectl-nvim.url = "github:Ramilito/kubectl.nvim/?ref=v2.39.2";

    # Development and formatting tools
    kulala-nvim.url = "github:mistweaverco/kulala.nvim";
    kulala-nvim.flake = false;
    kulala-fmt.url = "github:mistweaverco/kulala-fmt";
    kulala-fmt.inputs.flake-parts.follows = "flake-parts";
    kulala-fmt.inputs.nixpkgs.follows = "nixpkgs";


    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    neovim-nightly-overlay.inputs.nixpkgs.follows = "nixpkgs";
    neovim-nightly-overlay.inputs.flake-parts.follows = "flake-parts";
    nvim-treesitter-main.url = "github:iofq/nvim-treesitter-main";
    nvim-treesitter-main.inputs.nixpkgs.follows = "nixpkgs";

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

    namu-nvim = {
      url = "github:bassamsdata/namu.nvim";
      flake = false;
    };

    nvim-window = {
      url = "github:yorickpeterse/nvim-window";
      flake = false;
    };

    django-nvim = {
      url = "github:mizisu/django.nvim";
      flake = false;
    };

    # opencode.url = "github:anomalyco/opencode?ref=v1.1.63";
    # opencode.inputs.nixpkgs.follows = "nixpkgs";
    # opencode-nvim = {
    #   url = "github:sudo-tee/opencode.nvim?ref=22ee4f0f76e7b7de60a57f9a524893e50f0edbc4";
    #   flake = false;
    # };
    # 
    # nvim-aider = {
    #   url = "github:GeorgesAlkhouri/nvim-aider";
    #   flake = false;
    # };

    # my

    cmp-diag-codes = {
      url = "github:JMarkin/cmp-diag-codes";
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

              coding-packages = pkgs.coding-packages;
              small-coding-packages = pkgs.small-coding-packages;
              minimal-coding-packages = pkgs.minimal-coding-packages;

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
            };
          devShells = {
            default = pkgs.mkShell {
              name = "nvim-devShell";
              buildInputs = with pkgs; [
                jq
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
              '';
            };
          };
        };
      flake = {
        overlays.default = neovim-overlay;
        homeManagerModules.default = ((import ./nix/integration) "full");
        homeManagerModules.minimal = ((import ./nix/integration) "minimal");
        homeManagerModules.small = ((import ./nix/integration) "small");

        nixosManagerModules.default = ((import ./nix/integration) "full");
        nixosManagerModules.minimal = ((import ./nix/integration) "minimal");
        nixosManagerModules.small = ((import ./nix/integration) "small");
      };
    };
}
