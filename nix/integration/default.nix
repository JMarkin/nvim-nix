type:

{ lib, pkgs, options, config, ... }@ args:
let
  isNixOS = builtins.hasAttr "nixosConfig" args;

  nvim-spell-ru-utf8-dictionary = builtins.fetchurl {
    url = "https://ftp.cc.uoc.gr/pub/vim/runtime/spell/ru.utf-8.spl";
    sha256 = "";
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
    k8s = "nvim -c 'lua require(\"kubectl\").toggle({tab=true})'";
  };

  sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    MANPAGER = "nvim +Man!";
    LD_LIBRARY_PATH = ''${pkgs.sqlite-vec}/lib:'';
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
