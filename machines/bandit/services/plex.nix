{ pkgs, ... }:

{
  services.plex = let
  plexPass = pkgs.plex.override {
    plexRaw = pkgs.plexRaw.overrideAttrs (old: rec {
      version = "1.42.2.10122-3749b980e";  # replace with your Plex Pass version
      src = pkgs.fetchurl {
        url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
        sha256 = "9XIBRNSlLeA1YENSjGo2cM5n70xXrkw+d4q7lpqD7RY=";
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
