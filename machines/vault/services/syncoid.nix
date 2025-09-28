{ ... }:
{
  services = {
    syncoid = {
      enable = true;
      user = "syncoid";
      group = "syncoid";
      localTargetAllow = [ "create" "receive" "destroy" "mount" "send" ];
      interval = "daily";
      commands = {
        "nas" = {
          source = "storage/nas";
          target = "syncoid@bandit:data/nas";
          sshKey = /root/.ssh/id_ed25519;
        };
      };
    };
  };
}
