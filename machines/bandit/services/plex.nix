{ pkgs, ... }:

{
  services.plex = let
  plexPass = pkgs.plex.override {
    plexRaw = pkgs.plexRaw.overrideAttrs (old: rec {
      version = "1.43.0.10231-ca3956848";  # replace with your Plex Pass version
      src = pkgs.fetchurl {
        url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
        sha256 = "/TtUj/G7G6VPlEnhJny2e8Uqjr+EdBN80eB6KofVyBw=";
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
