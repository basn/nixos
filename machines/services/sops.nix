{ config, ... }:
{
  sops = {
    defaultSopsFile = ./secrets/services.yaml;
    age = {
      keyFile = "/home/basn/.config/sops/age/keys.txt";
    };
    secrets = {
      authentik = {
        sopsFile = ./secrets/authentik.env;
        format = "dotenv";
      };
      grafana-secret-key.restartUnits = [ "grafana.service" ];
      freshrss-password = { 
        owner = config.services.freshrss.user;
      };
      searx = {
        sopsFile = ./secrets/searx.env;
        format = "dotenv";
      };
      zfs-kuma-vaultwarden-replication = {
        sopsFile = ./secrets/zfs-kuma.yaml;
        key = "vaultwarden-replication";
      };
    };
  };
}
