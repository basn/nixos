{ config, pkgs, unstablePkgs, ... }:

{
  environment.systemPackages = with unstablePkgs; [
    jellyfin-ffmpeg
  ];

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    group = "plex";
    user = "plex";
    package = unstablePkgs.jellyfin;
    dataDir = "/data2/files/jellyfin";
    configDir = "/data2/files/jellyfin/config";
  };

}
