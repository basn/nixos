{ unstablePkgs, ... }:
{
  programs = {
    hyprland = {
      enable = true;
      package = unstablePkgs.hyprland;
    };
  };
  enviroment.systemPackages = with unstablePkgs; [
    waybar
    libnotify
    dunst
    hyprpaper
    ghostty
    kitty
    rofi-wayland
  ];
}
