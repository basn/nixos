{ config, lib, pkgs, unstablePkgs, ... }:
{
  services = {
    radarr = {
      enable = true;
      openFirewall = true;
      package = unstablePkgs.radarr;
      user = "plex";
      group = "plex";
      dataDir = "/data2/files/radarr/";
    };
  };
}
