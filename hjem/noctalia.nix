{ pkgs, ... }:
{
  xdg.portal = {
    enable = true;
    wlr = {
      enable = true;
      settings = {
        screencast = {
          chooser_type = "simple";
          chooser_cmd = "${pkgs.slurp}/bin/slurp -f 'Monitor: %o' -or";
        };
      };
    };
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
