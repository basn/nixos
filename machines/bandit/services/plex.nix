{ pkgs, ... }:

{
  services.plex = let
  plexPass = pkgs.plex.override {
    plexRaw = pkgs.plexRaw.overrideAttrs (old: rec {
      version = "1.43.0.10162-b67a664b6";  # replace with your Plex Pass version
      src = pkgs.fetchurl {
        url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
        sha256 = "0kpBxYrfvA5T9QHxOMRhqif6PHcUyuDYLOge787mth0=";
      };
    });
  };
in {
  enable = true;
  openFirewall = true;
  user = "plex";         # optional, your setup
  group = "plex";        # optional
  package = plexPass;
 };
  users.users.plex.extraGroups = [ "video" ];
}
