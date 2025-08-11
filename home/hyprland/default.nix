{ config, ... }:
{
  imports = [ ./waybar.nix ./hyprland.nix ./hypridle.nix ./hyprpaper.nix ./rofi.nix ./dunst.nix ];
  xdg.configFile."uwsm/env".source = "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
}
