{ pkgs, lib, config, ... }:
{
  stylix = {
    enable = config.programs.hyprland.enable;
    base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/onedark.yaml";
    polarity = "dark";
  };
}
