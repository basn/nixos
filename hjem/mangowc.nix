{ pkgs, config, ... }:
let
  monitorConfigFile =
    if config.networking.hostName == "laptop" then
      ./configs/mangowc/monitors-laptop.conf
    else
      ./configs/mangowc/monitors-battlestation.conf;
  mangowcConfig = pkgs.writeText "mangowc.conf" (
    builtins.readFile monitorConfigFile + builtins.readFile ./configs/mangowc/mangowc.conf
  );
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
