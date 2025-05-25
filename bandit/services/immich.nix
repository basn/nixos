let
  photosLocation = "/data/files/immich";
in
{ ... }:

{
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    user = "immich";
    group = "immich";
    mediaLocation = photosLocation;
    openFirewall = true;
    settings = {
      # TODO: configure or change to `null`
    };
  };
}
