{
  config,
  pkgs,
  ...
}:
let
  dataDir = "/var/lib/muxarr";
  muxarrImage = "ghcr.io/kirovair/muxarr:0.9.14@sha256:393248951e0fcc2f7d2354b396c1a8d305aab32d4dbff2c194d6f29f970e08f3";
  plexUid = toString config.users.users.plex.uid;
  plexGid = toString config.users.groups.plex.gid;
in
{
  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 plex plex - -"
  ];

  virtualisation.oci-containers = {
    backend = "podman";
    containers.muxarr = {
      image = muxarrImage;
      ports = [ "127.0.0.1:8183:8183" ];
      environment = {
        TZ = "Europe/Stockholm";
        PUID = plexUid;
        PGID = plexGid;
        UMASK = "002";
      };
      volumes = [
        "${dataDir}:/config"
        "/data/files:/data/files"
        "/mnt/telia:/mnt/telia"
      ];
    };
  };

  systemd.services.podman-muxarr = {
    requires = [ "rclone.service" ];
    after = [ "rclone.service" ];
    partOf = [ "rclone.service" ];
    bindsTo = [
      "data-files.mount"
      "rclone.service"
    ];
    unitConfig.RequiresMountsFor = [ "/data/files" ];
    preStart = ''
      if ! ${pkgs.util-linux}/bin/findmnt --mountpoint /data/files \
        --types zfs >/dev/null; then
        echo "Muxarr requires /data/files to be mounted as ZFS" >&2
        exit 1
      fi

      if ! ${pkgs.util-linux}/bin/findmnt --mountpoint /mnt/telia \
        --types fuse.rclone --source encrypted:/files/ >/dev/null; then
        echo "Muxarr requires /mnt/telia to be the encrypted:/files/ rclone mount" >&2
        exit 1
      fi
    '';
  };
}
