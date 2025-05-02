{ config, lib, pkgs, unstablePkgs, ... }:
{
  services = {
    prowlarr = {
      enable = true;
      openFirewall = true;
      package = unstablePkgs.prowlarr;
    };
  };
}
