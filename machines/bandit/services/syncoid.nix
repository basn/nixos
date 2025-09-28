{ pkgs, ... }:
{
  users.users.syncoid = {
    isSystemUser = true;
    home = "/var/lib/syncoid";
    createHome = true;
    shell = pkgs.bash;  # Needed for SSH
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/syncoid/.ssh 0700 syncoid syncoid -"
  ];
  systemd.services.zfs-permissions = {
    description = "Grant ZFS permissions to syncoid";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "grant-zfs-perms" ''
        ${pkgs.zfs}/bin/zfs allow -u syncoid send,hold,release data/nas
      '';
    };
  };
}
