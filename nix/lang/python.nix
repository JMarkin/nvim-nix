{ pkgs, lib, ... }:
let

  zuban = pkgs.rustPlatform.buildRustPackage
    (finalAttrs:
      let
        typeshedSrc = pkgs.fetchFromGitHub {
          owner = "python";
          repo = "typeshed";
          rev = "0e9b8c99ba01717d737de8b01ed647ef2f2ac9e5";
          sha256 = "sha256-btpuvJHw9dmVg0lEWRFe+JCx1f91O4T6/73TFgCxHNg=";
        };
      in
      {
        pname = "zuban";

        version = "2025-10-21";

        src = pkgs.fetchFromGitHub {
          owner = "zubanls";
          repo = "zuban";
          rev = "e05a3c57f07484c93c1573fdd90992f518ce2004";
          sha256 = "sha256-tVU0HsALH8UJtqSPlC0+t1r9gYdYxjQtyaBy8f+YFY8=";
        };

        buildAndTestSubdir = "crates/zuban";

        postInstall = ''
          mkdir -p $out/${pkgs.python3.sitePackages}/zuban
          cp -r ${typeshedSrc} $out/${pkgs.python3.sitePackages}/zuban/typeshed
        '';

        cargoHash = "sha256-Etjo2/2HKe0fOZKVrAaIZCWiuCp3TOmPGnbxBMfYCHA=";

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
      uv
    ];

  plugins = [ ];

}
