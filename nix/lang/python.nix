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
          rev="9ea8512d8852bd220b6ca8f0763aa50ba7c3c763";
          sha256="sha256-0yal71pidWCJ01xaz5X9LeE2hNYL75cQ7bzGcuIV/9k=";
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
