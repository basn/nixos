{ pkgs, ... }:

{
  services.plex =
    let
      plexPass = pkgs.plex.override {
        # Remove this override once nixpkgs provides Plex 1.43.5.11029 or newer.
        plexRaw = pkgs.plexRaw.overrideAttrs (old: rec {
          version = "1.43.5.11029-6bf8af3f0";
          src = pkgs.fetchurl {
            url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
            sha256 = "1q92fvkq6c2hlazgdmdklxdygmrjspjpz0rg30j8lcxyasadybjn";
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
