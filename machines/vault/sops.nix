{ ... }:

{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      zfs-kuma-nas-replication = {
        sopsFile = ./secrets/zfs-kuma.yaml;
        key = "nas-replication";
      };
      zfs-kuma-berget-replication = {
        sopsFile = ./secrets/zfs-kuma.yaml;
        key = "berget-replication";
      };
      nut-upsmon = {
        sopsFile = ../../secrets/nut.yaml;
        key = "password";
      };
    };
  };
}
