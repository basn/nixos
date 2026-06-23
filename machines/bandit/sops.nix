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
      gitea-actions-runner-env = {
        sopsFile = ./secrets/bandit.yaml;
        key = "gitea-actions-runner-env";
        restartUnits = [ "gitea-runner-codeberg.service" ];
      };
    };
  };
}
