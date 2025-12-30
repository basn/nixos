{ ... }:

{
  sops = {
    secrets = {
      coturn = {
        format = "yaml";
        sopsFile = ./secrets/netbird.yaml;
        key = "coturn";
        owner = "turnserver";
      };
      datastore = {
        format = "yaml";
        sopsFile = ./secrets/netbird.yaml;
        key = "datastore";
      };
      idp = {
        format = "yaml";
        sopsFile = ./secrets/netbird.yaml;
        key = "idp";
      };
    };
  };
}
