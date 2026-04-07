{ pkgs, config, ... }:
let
  monitorConfigFile =
    if config.networking.hostName == "laptop" then
      ./configs/mangowc/monitors-laptop.conf
    else
      ./configs/mangowc/monitors-battlestation.conf;
  mangowcConfigTemplate = builtins.readFile monitorConfigFile + builtins.readFile ./configs/mangowc/mangowc.conf;
  mangowcConfigText = builtins.replaceStrings [ "noctalia-shell" ] [ "${pkgs.noctalia-shell}/bin/noctalia-shell" ] mangowcConfigTemplate;
  mangowcConfig = pkgs.writeText "mangowc.conf" mangowcConfigText;
in
{
  hjem = {
    users = {
      basn = {
        packages = [
          pkgs.mangowc
        ];
        files = {
          ".config/mangowc/mangowc.conf".source = mangowcConfig;
          ".config/mangowc/scripts/screenshot-full.sh".source = ./configs/mangowc/scripts/screenshot-full.sh;
          ".config/mangowc/scripts/screenshot-region.sh".source =
            ./configs/mangowc/scripts/screenshot-region.sh;
          ".config/mangowc/scripts/screenshot-copy-region.sh".source =
            ./configs/mangowc/scripts/screenshot-copy-region.sh;
        };
      };
    };
  };
}
