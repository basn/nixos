{ pkgs, ... }:
{
  users ={
    users.syncoid = {
      isSystemUser = true;
      shell = pkgs.bash;
      group = "syncoid";
    };
    groups = {
      syncoid = {};
    };
  };
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
          sshKey = /var/lib/syncoid/.ssh/id_ed25519;
        };
        "berget" = {
          source = "storage/berget";
          target = "syncoid@bandit:data/berget";
          sshKey = /var/lib/syncoid/.ssh/id_ed25519;
        };
      };
    };
  };
}
