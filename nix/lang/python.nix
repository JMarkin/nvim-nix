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

        version = "2025-10-07";

        src = pkgs.fetchFromGitHub {
          owner = "zubanls";
          repo = "zuban";
          rev="66102a7ce1a999aa7857a5d9721e8afbb1ce4d37";
          sha256="sha256-Bz1M2afQ8vaC6IpgZyzp/JXoCIw8x7h26PjEHlaQNes=";
        };

        buildAndTestSubdir = "crates/zuban";

        postInstall = ''
          mkdir -p $out/${pkgs.python3.sitePackages}/zuban
          cp -r ${typeshedSrc} $out/${pkgs.python3.sitePackages}/zuban/typeshed
        '';

        cargoHash = "sha256-RQ/+YR67j9PwLz9vQ2HJUyEs1qYzG5JWfGt9vCEqx1o=";

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
