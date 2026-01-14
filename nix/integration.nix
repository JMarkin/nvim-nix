type:

{ lib, pkgs, options, config, ... }@ args:
let
  isNixOS = builtins.hasAttr "nixosConfig" args;

  nvim-spell-ru-utf8-dictionary = builtins.fetchurl {
    url = "http://ftp.gr.vim.org/pub/vim/runtime/spell/ru.utf-8.spl";
    sha256 = "sha256:0kf5vbk7lmwap1k4y4c1fm17myzbmjyzwz0arh5v6810ibbknbgb";
  };

  packages = {
    "full" = [ pkgs.nvim-pkg pkgs.coding-packages ];
    "minimal" = [ pkgs.nvim-minimal pkgs.minimal-coding-packages ];
    "small" = [ pkgs.nvim-small pkgs.small-coding-packages ];
  };
  defaultPackages = [ pkgs.nvim-minimal pkgs.minimal-coding-packages ];

  getPackages = env: default:
    if packages ? ${env} then packages.${env} else default;


  shellAliases = {
    vim = "nvim";
    v = "nvim";
    vi = "nvim";
    vimdiff = "nvim -d";
  };

  sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    MANPAGER = "nvim +Man!";
  };


  homeConfig = { } // lib.optionalAttrs (builtins.hasAttr "home" options)
    {
      home = {
        file = {
          ".local/share/nvim/site/spell/ru.utf-8.spl".source = nvim-spell-ru-utf8-dictionary;
          ".config/nvim/snippets".source = config.lib.file.mkOutOfStoreSymlink ../../nvim/snippets;
        };
        packages = getPackages type defaultPackages;
        shellAliases = shellAliases;
        sessionVariables = sessionVariables;
      };
    };
  nixOsConfig = { } // lib.optionalAttrs (builtins.hasAttr "environment" options)
    {
      environment = {
        systemPackages = getPackages type defaultPackages;
        shellAliases = shellAliases;
        sessionVariables = sessionVariables;
      };
    };


in
{


  config = lib.mkMerge [
    (lib.mkIf (!isNixOS) homeConfig)
    (lib.mkIf isNixOS nixOsConfig)
  ];

}
