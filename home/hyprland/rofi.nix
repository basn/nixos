{ pkgs, ... }:
{
  programs = {
    rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      extraConfig = {
        modes = [ "combi" ];
        combi-modes = [ "window" "drun" "run" ];
        show-icons = true;
        matching = "fuzzy";
      };
    };
  };
}
