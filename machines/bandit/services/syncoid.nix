{ pkgs, ... }:
{
  users ={
    users.syncoid = {
      isSystemUser = true;
      home = "/var/lib/syncoid";
      createHome = true;
      shell = pkgs.bash;
      group = "syncoid";
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAQXGCj7idWd63vSz70F3wA0jGnGeKVz1bLZlRwsv34z root@vault" ];
      packages = [ pkgs.mbuffer pkgs.lzop ];
    };
    groups = {
      syncoid = {};
    };
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
        ${pkgs.zfs}/bin/zfs allow -u syncoid compression,mountpoint,create,mount,receive,rollback,destroy data/nas
        ${pkgs.zfs}/bin/zfs allow -u syncoid compression,mountpoint,create,mount,receive,rollback,destroy data/berget
      '';
    };
  };
}
