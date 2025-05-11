{ config, pkgs, sops, ... }:

{
  sops = {
    defaultSopsFile = ./secrets/services.yaml;
    age = {
      keyFile = "/home/basn/.config/sops/age/keys.txt";
    };
    secrets = {
      "vaultwarden/admintoken" = {};
      "vaultwarden/dbuser" = {};
      "vaultwarden/dbpass" = {};
      "teslamate/enckey" = {};
      "teslamate/dbuser" = {};
      "teslamate/dbpass" = {};
      "teslamate/mqttuser" = {};
      "teslamate/mqttpass" = {};
    };
  };
}
