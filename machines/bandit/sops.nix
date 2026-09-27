{ ... }:

{
  sops = {
    defaultSopsFile = ./secrets/bandit.yaml;
    secrets = {
      wg = {
        format = "binary";
        sopsFile = ./secrets/wg.conf;
      };
      atticd-env = {
        sopsFile = ./secrets/bandit.yaml;
        key = "atticd-env";
        restartUnits = [ "atticd.service" ];
      };
      seedport = {
        sopsFile = ./secrets/bandit.yaml;
        key = "seedport";
        restartUnits = [ "qbittorrent.service" ];
      };
      azire-portforward-token = {
        sopsFile = ./secrets/bandit.yaml;
        key = "azire-portforward-token";
        mode = "0400";
      };
      unpackerr-env = {
        sopsFile = ./secrets/bandit.yaml;
        key = "unpackerr-env";
        mode = "0400";
        restartUnits = [ "unpackerr.service" ];
      };
      pinepods-postgres-superuser-password = {
        key = "pinepods/postgres-superuser-password";
      };
      pinepods-db-password = {
        key = "pinepods/db-password";
      };
      pinepods-admin-password = {
        key = "pinepods/admin-password";
      };
      pinepods-oidc-client-secret = {
        key = "pinepods/oidc-client-secret";
      };
    };
  };
}
