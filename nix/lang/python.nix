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

        version = "2025-11-01";

        src = pkgs.fetchFromGitHub {
          owner = "zubanls";
          repo = "zuban";
          rev = "cd8a71b5b05aa09a2449e26aa47653888ff39f3c";
          sha256 = "sha256-degXEZMuaW7jmagGNKkvO+6Kf1FIDeOMlSi1OKZyqpY=";
        };

        buildAndTestSubdir = "crates/zuban";

        postInstall = ''
          mkdir -p $out/${pkgs.python3.sitePackages}/zuban
          cp -r ${typeshedSrc} $out/${pkgs.python3.sitePackages}/zuban/typeshed
        '';

        cargoHash = "sha256-gdHFI/HFQKoWixPeVX4xG5V1NaKPUJ9d6BX/dZWYOYg=";

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
