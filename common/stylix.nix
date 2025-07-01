{ pkgs, lib, config, ... }:
{
  stylix = {
    enable = config.programs.hyprland.enable;
    base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/onedark.yaml";
    polarity = "dark";
    fonts = {
      monospace = {
        name = "MesloLGS NF";
      };
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
    };
  };
}
