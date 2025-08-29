{ pkgs, ... }:

{
  services.plex = let
  plexPass = pkgs.plex.override {
    plexRaw = pkgs.plexRaw.overrideAttrs (old: rec {
      version = "v.1.42.2.10102-50deb00d9";  # replace with your Plex Pass version
      src = pkgs.fetchurl {
        url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
        sha256 = "3a822dbc6d08a6050a959d099b30dcd96a8cb7266b94d085ecc0a750aa8197f4";
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
