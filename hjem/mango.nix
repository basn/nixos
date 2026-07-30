{
  pkgs,
  config,
  lib,
  ...
}:
let
  monitorConfigFile =
    if config.networking.hostName == "laptop" then
      ./configs/mango/monitors-laptop.conf
    else
      ./configs/mango/monitors-battlestation.conf;
  mangoConfigTemplate =
    builtins.readFile monitorConfigFile + builtins.readFile ./configs/mango/mango.conf;
  mangoConfigText =
    builtins.replaceStrings [ "noctalia-shell" ] [ "${pkgs.noctalia-shell}/bin/noctalia-shell" ]
      mangoConfigTemplate;
  mangoConfig = pkgs.writeText "mango.conf" mangoConfigText;
  mangoPackage = pkgs.mango;
in
{
  services.gnome.gnome-keyring.enable = lib.mkIf config.programs.mango.enable true;

  hjem = {
    users = {
      basn = {
        packages = [
          mangoPackage
        ];
        files = {
          ".config/mango/config.conf".source = mangoConfig;
          ".config/mango/scripts/screenshot-full.sh".source = ./configs/mango/scripts/screenshot-full.sh;
          ".config/mango/scripts/screenshot-region.sh".source = ./configs/mango/scripts/screenshot-region.sh;
          ".config/mango/scripts/screenshot-copy-region.sh".source =
            ./configs/mango/scripts/screenshot-copy-region.sh;
        };
      };
    };
  };
}
