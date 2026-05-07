{ pkgs, ... }:
{
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  hjem = {
    users = {
      basn = {
        packages = with pkgs; [
          noctalia-shell
          satty
        ];
        files = {
          ".config/noctalia/settings.json".source = ./configs/noctalia-settings.json;
        };
      };
    };
  };
}
