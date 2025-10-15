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
      interval = "daily";
      localTargetAllow = [
        "change-key"
        "compression"
        "create"
        "mount"
        "mountpoint"
        "receive"
        "rollback"
        "destroy"
        ];
      commands = {
        "cygate-berget" = {
          source = "storage/berget";
          target = "syncoid@nixos-sov:backup/berget";
          sshKey = /var/lib/syncoid/.ssh/id_ed25519;
        };
        "cygate-nas" = {
          source = "storage/nas";
          target = "syncoid@nixos-sov:backup/nas";
          sshKey = /var/lib/syncoid/.ssh/id_ed25519;
        };
        "site1-nas" = {
          source = "storage/nas";
          target = "syncoid@nixos-sov2:backup/nas";
          sshKey = /var/lib/syncoid/.ssh/id_ed25519;
        };
      };
    };
  };
}
