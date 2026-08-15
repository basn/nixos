{ ... }:

{
  sops = {
    defaultSopsFile = ./secrets/bandit.yaml;
    age = {
      #      sshKeyPaths = [ "/home/basn/.ssh/id_ed25519" ];
      keyFile = "/home/basn/.config/sops/age/keys.txt";
    };
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
    };
  };
}
