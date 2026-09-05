let
  photosLocation = "/data/immich";
in
{ unstablePkgs, ... }:

{
  users.users.immich.extraGroups = [
    "video"
    "render"
  ];
  services.immich = {
    enable = true;
    package = unstablePkgs.immich;
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
