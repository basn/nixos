{
  inputs,
  lib,
  unstablePkgs,
  ...
}:
let
  prowlarrModule = import "${inputs.nixpkgs-unstable.outPath}/nixos/modules/services/misc/servarr/prowlarr.nix";
  dataDir = "/data2/files/prowlarr/";
in
{
  disabledModules = [ "services/misc/servarr/prowlarr.nix" ];
  imports = [ prowlarrModule ];

  users = {
    groups.prowlarr = { };
    users.prowlarr = {
      isSystemUser = true;
      group = "prowlarr";
    };
  };

  services = {
    prowlarr = {
      enable = true;
      openFirewall = true;
      package = unstablePkgs.prowlarr;
      inherit dataDir;
    };
  };

  # The upstream module uses DynamicUser and otherwise resets a custom data
  # directory to root:root during activation. A static account keeps ownership
  # stable across upgrades while retaining the module's bind-mount layout.
  systemd.tmpfiles.settings."10-prowlarr".${dataDir} = {
    d = {
      user = lib.mkForce "prowlarr";
      group = lib.mkForce "prowlarr";
      mode = lib.mkForce "0700";
    };
    Z = {
      user = "prowlarr";
      group = "prowlarr";
      mode = "-";
    };
  };

  systemd.services.prowlarr.serviceConfig = {
    User = "prowlarr";
    Group = "prowlarr";
  };
}
