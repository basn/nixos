{ ... }:

{
  sops = {
    secrets = {
      coturn = {
        format = "yaml";
        sopsFile = ./secrets/netbird.yaml;
        key = "coturn";
        owner = "turnserver";
        restartUnits = [
          "coturn.service"
          "netbird-management.service"
        ];
      };
      datastore = {
        format = "yaml";
        sopsFile = ./secrets/netbird.yaml;
        key = "datastore";
        restartUnits = [ "netbird-management.service" ];
      };
      idp = {
        format = "yaml";
        sopsFile = ./secrets/netbird.yaml;
        key = "idp";
        restartUnits = [ "netbird-management.service" ];
      };
    };
  };
}
