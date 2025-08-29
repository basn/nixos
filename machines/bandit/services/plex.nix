{ pkgs, ... }:

{
  services.plex = let
  plexPass = pkgs.plex.override {
    plexRaw = pkgs.plexRaw.overrideAttrs (old: rec {
      version = "1.42.2.10102-50deb00d9";  # replace with your Plex Pass version
      src = pkgs.fetchurl {
        url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
        sha256 = "YR8ir/2SGTqJE+HXBKeG5LqsE1JZnkdjtKSdtFBNVOY=";
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
