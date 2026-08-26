{ pkgs, ... }:

{
  services.plex =
    let
      plexPass = pkgs.plex.override {
        plexRaw = pkgs.plexRaw.overrideAttrs (old: rec {
          version = "1.43.4.10903-e5521bd8c";
          src = pkgs.fetchurl {
            url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
            sha256 = "1nry7dffb5lv30mqmcb6d9pssjw8951r79ji07rf2yfp6s1iqskg";
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
