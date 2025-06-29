{ pkgs, ... }:
{
  programs = {
    hyprland = {
      enable = true;
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
  ];
}
