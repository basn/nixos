{ pkgs, lib, ... }:
{
  stylix = {
    enable = true;
    base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/onedark.yaml";
    polarity = "dark";
  };
}
