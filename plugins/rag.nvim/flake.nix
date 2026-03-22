{
  description = "RAG Plugin for Neovim with SQLite-Vec";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = { flake-parts, ... } @inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { self', pkgs, ... }:
        let
          deps = with pkgs; [
            vimPlugins.sqlite-lua
            vimPlugins.plenary-nvim
            sqlite-vec
            sqlite
            ripgrep
            curl
          ];
        in
        {
          packages = {
            rag-nvim = (pkgs.vimUtils.buildVimPlugin {
              pname = "rag.nvim";
              version = "0.0.1";
              src = ./.;
              buildInputs = deps;
              preInstall = ''
                mkdir -p lib
                ln -s ${pkgs.sqlite-vec}/lib/*vec0* lib/
              '';
            }).overrideAttrs {
              dependencies = deps;
            };

            default = self'.packages.rag-nvim;
          };

        };

    };
}

