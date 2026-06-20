{ ... }:

{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      zfs = {
        format = "yaml";
        sopsFile = ../../secrets/zfs.yaml;
        key = "password";
      };
      zfs-kuma-nas-replication = {
        sopsFile = ./secrets/zfs-kuma.yaml;
        key = "nas-replication";
      };
      zfs-kuma-berget-replication = {
        sopsFile = ./secrets/zfs-kuma.yaml;
        key = "berget-replication";
      };
    };
  };
}
