{
  config,
  lib,
  pkgs,
  ...
}:

{
  users = {
    users.atticd = {
      isSystemUser = true;
      group = "atticd";
    };
    groups.atticd = { };
  };

  systemd.tmpfiles.rules = [
    "d /data/attic 0750 atticd atticd - -"
    "d /data/attic/storage 0750 atticd atticd - -"
  ];

  systemd.services.atticd = {
    after = [
      "data-attic.mount"
      "systemd-tmpfiles-setup.service"
      "systemd-tmpfiles-resetup.service"
    ];
    requires = [ "data-attic.mount" ];
    wants = [
      "systemd-tmpfiles-setup.service"
      "systemd-tmpfiles-resetup.service"
    ];
    serviceConfig.DynamicUser = lib.mkForce false;
  };

  services.atticd = {
    enable = true;
    environmentFile = config.sops.secrets.atticd-env.path;
    settings = {
      listen = "0.0.0.0:8081";
      api-endpoint = "https://attic.basn.se/";
      database.url = "sqlite:///var/lib/atticd/server.db?mode=rwc";
      storage = {
        type = "local";
        path = "/data/attic/storage";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 8081 ];

  environment.systemPackages = with pkgs; [
    attic-client
    attic-server
  ];
}
