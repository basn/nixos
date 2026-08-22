{ config, pkgs, ... }:

let
  # Define your variables here
  rcloneConfigPath = "/root/.config/rclone/rclone.conf";
  logFile = "/var/log/rclone-log.txt";
  mountPoint = "/mnt/telia";
  cacheDir = "/data2/rclone-cache";
  bwlimit = "50M:off";
  vfsCacheMaxSize = "185G";
  vfsCacheMaxAge = "438300h";
  vfsReadChunkSize = "16M";
  vfsReadChunkSizeLimit = "1G";
  vfsReadChunkStreams = 4;
in

{
  systemd.services.rclone = {
    description = "Telia Crypt (rclone)";
    after = [ "network.target" ];
    unitConfig.RequiresMountsFor = [ cacheDir ];

    serviceConfig = {
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount \
          --log-file=${logFile} \
          --progress \
          --stats=1m \
          --log-level=INFO \
          --config=${rcloneConfigPath} \
          --allow-other \
          --allow-non-empty \
          --use-mmap \
          --transfers=8 \
          --cache-dir=${cacheDir} \
          --dir-cache-time=10000h \
          --buffer-size 100M \
          --vfs-cache-mode full \
          --vfs-read-chunk-size ${vfsReadChunkSize} \
          --vfs-read-chunk-size-limit ${vfsReadChunkSizeLimit} \
          --vfs-read-chunk-streams ${toString vfsReadChunkStreams} \
          --vfs-cache-max-age ${vfsCacheMaxAge} \
          --vfs-cache-max-size ${vfsCacheMaxSize} \
          --umask=0000 encrypted:/files/ ${mountPoint} \
          --bwlimit ${bwlimit} \
          --jottacloud-hard-delete
      '';
      ExecStop = "${pkgs.fuse}/bin/fusermount -u ${mountPoint}";
      Restart = "always";
      RestartSec = 10;
    };

    wantedBy = [ "default.target" ];
  };
}
