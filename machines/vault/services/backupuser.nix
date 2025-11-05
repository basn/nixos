{ pkgs, ... }:
{
  users = {
    users.zfsbackup = {
      isSystemUser = true;
      createHome = true;
      shell = pkgs.bash;
      openssh.authorizedKeys.keys = [ "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAAqWEcRiqHQjTc51d54Ws46uNpo0JYc3BBFiWVdTOpxRYGL7mFZNJ8is8srJYpI0MIWNADF2xicgZ2VfYMiQ0S2MwAc7ax+HTx+/RXQEPbPJ5xelJlM1+W8k4Uh4QDvKW9kIGiMeDgtlfgCZQxekX1AmBxSOQuIyRMq0JqFCJ54AO372Q== root@services" ];
      packages = [ pkgs.mbuffer pkgs.lzop ];
      group = "zfsbackup";
    };
    groups.zfsbackup = {};
  };
  systemd.services.zfs-permissions = {
    description = "Grant ZFS permissions to zfsbackup";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "grant-zfs-perms" ''
        ${pkgs.zfs}/bin/zfs create storage/backup
        ${pkgs.zfs}/bin/zfs allow -u zfsbackup compression,mountpoint,create,mount,receive,rollback,destroy storage/backup
      '';
    };
  };
}

