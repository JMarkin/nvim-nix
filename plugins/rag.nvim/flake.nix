{
  description = "RAG Plugin for Neovim with SQLite-Vec";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { flake-parts, nixpkgs, ... } @inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      perSystem = { self', config, inputs', pkgs, system, lib, ... }: {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          overlays = [ inputs.fenix.overlays.default ];
        };

        packages =
          let
            fs = lib.fileset;

            rustFs = fs.unions [
              (fs.fileFilter (file: lib.hasPrefix "Cargo" file.name) ./.)
              (fs.fileFilter (file: file.hasExt "rs") ./.)
            ];

            nvimFs = fs.difference ./. (fs.unions [ rustFs ]);

            version = "0.0.1";

            rag-rust-lib =
              let
                inherit (inputs'.fenix.packages.minimal) toolchain;

                rustPlatform = pkgs.makeRustPlatform {
                  cargo = toolchain;
                  rustc = toolchain;
                };

                src = ./rag-rust;
              in
              rustPlatform.buildRustPackage {
                pname = "rag-rust-lib";
                inherit version;
                src = src;
                cargoLock = { lockFile = src + "/Cargo.lock"; };
                buildInputs = with pkgs; lib.optionals stdenv.hostPlatform.isAarch64 [ rust-jemalloc-sys ];
                nativeBuildInputs = with pkgs; [ git ];

                env = {
                  RUSTFLAGS = with pkgs;
                    lib.optionalString stdenv.hostPlatform.isDarwin "-C link-arg=-undefined -C link-arg=dynamic_lookup";
                };
              };

            rag-nvim = pkgs.vimUtils.buildVimPlugin {
              pname = "rag.nvim";
              inherit version;
              src = fs.toSource {
                root = ./.;
                fileset = nvimFs;
              };
              preInstall = ''
                mkdir -p lib
                ln -s ${self'.packages.rag-rust-lib}/lib/librag.* lib/
              '';
            };

          in
          {
            rag-rust-lib = rag-rust-lib;
            rag-nvim = rag-nvim;
            default = self'.packages.rag-nvim;
          };

        devShells.default = pkgs.mkShell {
          name = "rag";
          inputsFrom = [
            self'.packages.rag-rust-lib
            self'.packages.rag-nvim
          ];
          packages = with pkgs; [ rust-analyzer ];

          shellHook = ''
            export LD_LIBRARY_PATH="${lib.makeLibraryPath [ pkgs.sqlite-vec pkgs.libiconv ]}:$LD_LIBRARY_PATH"
          '';
        };

        formatter = pkgs.nixfmt-classic;
      };
    };
}

