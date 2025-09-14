{ pkgs, ... }:
{
  programs = {
    hyprland = {
      enable = true;
      withUWSM = true;
    };
  };
  environment.systemPackages = with pkgs; [
    waybar
    waybar-mpris
    libnotify
    dunst
    hyprpaper
    ghostty
    kitty
    rofi
    hyprlock
    pavucontrol
    hypridle
    hyprshot
    hyprcursor
    playerctl
  ];
}
