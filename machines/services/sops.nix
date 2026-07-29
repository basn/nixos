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
      typetype = {
        sopsFile = ./secrets/typetype.env;
        format = "dotenv";
      };
      typetype-s3-access-key = {
        sopsFile = ./secrets/typetype.env;
        format = "dotenv";
        key = "DOWNLOADER_S3_ACCESS_KEY";
      };
      typetype-s3-secret-key = {
        sopsFile = ./secrets/typetype.env;
        format = "dotenv";
        key = "DOWNLOADER_S3_SECRET_KEY";
      };
      zfs-kuma-vaultwarden-replication = {
        sopsFile = ./secrets/zfs-kuma.yaml;
        key = "vaultwarden-replication";
      };
    };
  };
}
