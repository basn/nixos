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
    };
  };
}
