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
    libnotify
    dunst
    hyprpaper
    ghostty
    kitty
    rofi-wayland
    hyprlock
    pavucontrol
    hypridle
    hyprshot
    hyprcursor
    playerctl
  ];
}
