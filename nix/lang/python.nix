{ pkgs, lib, ... }:
let

  zuban = pkgs.rustPlatform.buildRustPackage
    (finalAttrs:
      let
        typeshedSrc = pkgs.fetchFromGitHub {
          owner = "python";
          repo = "typeshed";
          rev = "1b267b25f2c726291e4e6627b7567f2c8dc04b60";
          sha256 = "sha256-SQJypewNYLfNSIc+Myd9l+nypdMdOx+Fyymmg/YpFW4=";
        };
      in
      {
        pname = "zuban";

        version = "2025-09-16";

        src = pkgs.fetchFromGitHub {
          owner = "zubanls";
          repo = "zuban";
          rev="1dd7a1cb4e111116f19e29b713d3b6d6eb6ae01d";
          sha256="sha256-L/ZQgwYAJHw5M6dgoOpKjE0SbA71fTXBxyRDeEB+TxM=";
        };

        buildAndTestSubdir = "crates/zuban";

        postInstall = ''
          mkdir -p $out/${pkgs.python3.sitePackages}/zuban
          cp -r ${typeshedSrc} $out/${pkgs.python3.sitePackages}/zuban/typeshed
        '';

        cargoHash = "sha256-TAFdS4NmXchmhqVRcsckz6GhZG35IE2fukDlZiRF8Ms=";

        doInstallCheck = true;

        meta = {
          description = "Mypy-compatible Python Language Server built in Rust";
          homepage = "https://zubanls.com";
          # There's no changelog file yet, but they post updates on their blog.
          changelog = "https://zubanls.com/blog/";
          license = lib.licenses.agpl3Only;
          platforms = lib.platforms.all;
          mainProgram = "zuban";
        };
      });
in
{
  packages = with pkgs;
    [
      python313Packages.ipython

      ruff
      # ty
      zuban
    ];

  plugins = [ ];

}
