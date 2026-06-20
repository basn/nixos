{ config, pkgs, ... }:
let
  kumaPush = pkgs.writeShellScript "zfs-kuma-vaultwarden-replication" ''
    set -u

    if [[ "''${WORKER:-}" == *-refresh ]]; then
      exit 0
    fi

    token="$(${pkgs.coreutils}/bin/tr -d '\r\n' < ${config.sops.secrets.zfs-kuma-vaultwarden-replication.path})"

    ${pkgs.curl}/bin/curl \
      --fail \
      --silent \
      --show-error \
      --max-time 15 \
      --get \
      --data-urlencode "status=up" \
      --data-urlencode "msg=Vaultwarden replication to vault completed" \
      "https://uptime.basn.se/api/push/$token"
  '';
in
{
  services.znapzend = {
    enable = true;
    autoCreation = true;
    pure = true;
    zetup = {
      "tank/vaultwarden" = {
        enable = true;
        recursive = true;
        mbuffer.enable = false;
        plan = "1d=>4h,1w=>1d";
        timestampFormat = "%Y-%m-%d-%H%M%S";
        destinations = {
          "vault" = {
            dataset = "storage/backup";
            plan = "1w=>1d";
            host = "zfsbackup@vault";
            postsend = "${kumaPush}";
          };
        };
      };
    };
  };
}
