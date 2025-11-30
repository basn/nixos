{
  config,
  lib,
  pkgs,
  unstablePkgs,
  ...
}:
{
  services = {
    sonarr = {
      enable = true;
      openFirewall = true;
      package = unstablePkgs.sonarr;
      user = "plex";
      group = "plex";
      dataDir = "/data2/files/sonarr/";
    };
  };
}
