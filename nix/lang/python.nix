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
        djangoStubsSrc = pkgs.fetchFromGitHub {
          owner = "typeddjango";
          repo = "django-stubs";
          rev = "e82f5d126b1e15281e2e32ce746ce38e25105952";
          sha256 = "sha256-MCgunXCPmTp1dOerB+u2d1F6TZOpGYWc9Qb6DYPi9Mk=";
        };
      in
      {
        pname = "zuban";

        version = "2025-12-05";

        src = pkgs.fetchFromGitHub {
          owner = "zubanls";
          repo = "zuban";
          rev = "1adc194449720ce476b2b3f3ebf3975063d67f30";
          sha256 = "sha256-FPWW4BRCy4O4RyMhFVq4Vd8u+0MjRqNpYJirvIV8RSw=";
        };

        buildAndTestSubdir = "crates/zuban";

        postInstall = ''
          mkdir -p $out/${pkgs.python3.sitePackages}/zuban
          cp -r ${typeshedSrc} $out/${pkgs.python3.sitePackages}/zuban/third_party/typeshed
          cp -r ${djangoStubsSrc} $out/${pkgs.python3.sitePackages}/zuban/third_party/django-stubs
        '';

        cargoHash = "";

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
