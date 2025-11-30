{ pkgs, ... }:

{
  services.plex =
    let
      plexPass = pkgs.plex.override {
        plexRaw = pkgs.plexRaw.overrideAttrs (old: rec {
          version = "1.43.0.10346-fc911a729"; # replace with your Plex Pass version
          src = pkgs.fetchurl {
            url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
            sha256 = "jfQ11luQoafUYb5sGpvE7jPiErGt2HXVLwn70M/Hqyc=";
          };
        });
      };
    in
    {
      enable = true;
      openFirewall = true;
      user = "plex"; # optional, your setup
      group = "plex"; # optional
      package = plexPass;
    };
  users.users.plex.extraGroups = [ "video" ];
}
