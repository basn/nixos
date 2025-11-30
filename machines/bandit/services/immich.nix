let
  photosLocation = "/data/files/immich";
in
{ ... }:

{
  users.users.immich.extraGroups = [
    "video"
    "render"
  ];
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    user = "immich";
    group = "immich";
    mediaLocation = photosLocation;
    openFirewall = true;
    accelerationDevices = null;
    settings = {
      # TODO: configure or change to `null`
    };
  };
}
