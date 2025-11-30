{
  config,
  pkgs,
  sops,
  ...
}:

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
    };
  };
}
