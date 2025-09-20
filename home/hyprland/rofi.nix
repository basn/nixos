{ pkgs, ... }:
{
  programs = {
    rofi = {
      enable = true;
      package = pkgs.rofi;
      extraConfig = {
        modes = [ "combi" ];
        combi-modes = [ "window" "drun" "run" ];
        show-icons = true;
        matching = "fuzzy";
        display-drun = "";
        display-combi = "";
      };
    };
  };
}
