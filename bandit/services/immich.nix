let
  immichPort = 8080;
  immichHost = "192.168.195.43";
  photosLocation = "/data/files/immich";
in
{ ... }:

{
  services.immich = {
    enable = true;
    port = immichPort;
    host = immichHost;
    user = "immich";
    group = "immich";
    mediaLocation = photosLocation;
    openFirewall = true;
    settings = {
      # TODO: configure or change to `null`
    };
  };
}
