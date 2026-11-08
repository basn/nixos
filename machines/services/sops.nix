{ config, ... }:
{
  sops = {
    defaultSopsFile = ./secrets/services.yaml;
    secrets = {
      authentik = {
        sopsFile = ./secrets/authentik.env;
        format = "dotenv";
      };
      grafana-secret-key = {
        owner = "grafana";
        restartUnits = [ "grafana.service" ];
      };
      freshrss-password = {
        owner = config.services.freshrss.user;
      };
      searx = {
        sopsFile = ./secrets/searx.env;
        format = "dotenv";
      };
      vikunja-service-secret = {
        sopsFile = ./secrets/vikunja.yaml;
        restartUnits = [ "vikunja.service" ];
      };
      vikunja-oidc-client-secret = {
        sopsFile = ./secrets/vikunja.yaml;
        restartUnits = [ "vikunja.service" ];
      };
      zfs-kuma-vaultwarden-replication = {
        sopsFile = ./secrets/zfs-kuma.yaml;
        key = "vaultwarden-replication";
      };
      pinepods-oidc-client-secret = {
        key = "pinepods/oidc-client-secret";
        restartUnits = [ "podman-authentik-worker.service" ];
      };
    };
  };
}
