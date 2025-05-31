{ ... }:
{
  sops = {
    defaultSopsFile = ./secrets/services.yaml;
    age = {
      keyFile = "/home/basn/.config/sops/age/keys.txt";
    };
    secrets = {
      teslamate = {
        sopsFile = ./secrets/teslamate.env;
      };
    };
  };
}
