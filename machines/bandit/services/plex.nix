{ pkgs, ... }:

{
  services.plex =
    let
      plexPass = pkgs.plex.override {
        # Remove this override once nixpkgs provides Plex 1.43.5.11079 or newer.
        plexRaw = pkgs.plexRaw.overrideAttrs (old: rec {
          version = "1.43.5.11079-b3b13e506";
          src = pkgs.fetchurl {
            url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
            sha256 = "01m2hwngl54nfq7gjiplkpp3in0z2iwq4ff4bj96wvg0jwfagsbl";
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
