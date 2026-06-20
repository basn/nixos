{ config, pkgs, ... }:
let
  mkKumaPush =
    name: secret: message:
    pkgs.writeShellScript "zfs-kuma-${name}" ''
      set -u

      if [[ "''${WORKER:-}" == *-refresh ]]; then
        exit 0
      fi

      token="$(${pkgs.coreutils}/bin/tr -d '\r\n' < ${secret})"

      ${pkgs.curl}/bin/curl \
        --fail \
        --silent \
        --show-error \
        --max-time 15 \
        --get \
        --data-urlencode "status=up" \
        --data-urlencode "msg=${message}" \
        "https://uptime.basn.se/api/push/$token"
    '';

  nasKumaPush =
    mkKumaPush "nas-replication" config.sops.secrets.zfs-kuma-nas-replication.path
      "NAS replication to nixos-sov completed";
  bergetKumaPush =
    mkKumaPush "berget-replication" config.sops.secrets.zfs-kuma-berget-replication.path
      "Berget replication to nixos-sov completed";
in
{
  services.znapzend = {
    enable = true;
    autoCreation = true;
    pure = true;
    zetup = {
      "storage/nas" = {
        enable = true;
        recursive = true;
        mbuffer.enable = false;
        plan = "1d=>4h,1w=>1d";
        timestampFormat = "%Y-%m-%d-%H%M%S";
        destinations = {
          "nixos-sov" = {
            dataset = "backup/nas";
            plan = "1w=>1d";
            host = "syncoid@nixos-sov";
            postsend = "${nasKumaPush}";
          };
        };
      };
      "storage/berget" = {
        enable = true;
        recursive = true;
        mbuffer.enable = false;
        plan = "1d=>4h,1w=>1d";
        timestampFormat = "%Y-%m-%d-%H%M%S";
        destinations = {
          "nixos-sov" = {
            dataset = "backup/berget";
            plan = "1w=>1d";
            host = "syncoid@nixos-sov";
            postsend = "${bergetKumaPush}";
          };
        };
      };
    };
  };
}
