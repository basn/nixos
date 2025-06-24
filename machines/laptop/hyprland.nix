{ pkgs, ... }:
{
  programs = {
    hyprland = {
      enable = true;
    };
  };
  enviroment.systemPackages = with pkgs; [
    waybar
    libnotify
    dunst
    hyprpaper
    ghostty
    kitty
    rofi-wayland
  ];
}
