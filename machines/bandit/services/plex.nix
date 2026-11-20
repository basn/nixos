{ pkgs, ... }:

{
  services.plex =
    let
      plexPass = pkgs.plex.override {
        # Remove this override once nixpkgs provides Plex 1.43.6.11100 or newer.
        plexRaw = pkgs.plexRaw.overrideAttrs (old: rec {
          version = "1.43.6.11100-5215553a5";
          src = pkgs.fetchurl {
            url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
            sha256 = "07ypz791wmh80xh2ralm7i4d7iykshpn0jaffavh2m6hfii5b0ja";
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
