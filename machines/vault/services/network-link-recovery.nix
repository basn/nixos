{ pkgs, ... }:
let
  interface = "enp1s0";
  downThresholdSeconds = 300;
  retryCooldownSeconds = 900;
in
{
  systemd.services.vault-network-link-recovery = {
    description = "Recover Vault Ethernet after sustained carrier loss";
    after = [ "network.target" ];

    path = with pkgs; [
      coreutils
      iproute2
    ];

    serviceConfig = {
      Type = "oneshot";
      RuntimeDirectory = "vault-network-link-recovery";
      RuntimeDirectoryMode = "0700";
      UMask = "0077";

      CapabilityBoundingSet = [ "CAP_NET_ADMIN" ];
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectSystem = "strict";
      RestrictSUIDSGID = true;
    };

    script = ''
      set -euo pipefail

      interface=${interface}
      carrier_file=/sys/class/net/$interface/carrier
      state_dir=/run/vault-network-link-recovery
      first_down_file=$state_dir/first-down
      last_attempt_file=$state_dir/last-attempt

      if [ ! -r "$carrier_file" ]; then
        echo "Interface $interface or its carrier state is unavailable" >&2
        exit 1
      fi

      now=$(date +%s)
      carrier=$(cat "$carrier_file")

      if [ "$carrier" = 1 ]; then
        rm -f "$first_down_file" "$last_attempt_file"
        exit 0
      fi

      if [ ! -s "$first_down_file" ]; then
        printf '%s\n' "$now" > "$first_down_file"
        echo "Carrier loss detected on $interface; waiting ${toString downThresholdSeconds} seconds before recovery"
        exit 0
      fi

      first_down=$(cat "$first_down_file")
      case "$first_down" in
        *[!0-9]*|"")
          printf '%s\n' "$now" > "$first_down_file"
          exit 0
          ;;
      esac

      down_for=$((now - first_down))
      if [ "$down_for" -lt ${toString downThresholdSeconds} ]; then
        exit 0
      fi

      last_attempt=0
      if [ -s "$last_attempt_file" ]; then
        candidate=$(cat "$last_attempt_file")
        case "$candidate" in
          *[!0-9]*|"") ;;
          *) last_attempt=$candidate ;;
        esac
      fi

      since_attempt=$((now - last_attempt))
      if [ "$since_attempt" -lt ${toString retryCooldownSeconds} ]; then
        exit 0
      fi

      printf '%s\n' "$now" > "$last_attempt_file"
      echo "Carrier on $interface has been down for $down_for seconds; cycling the interface"
      ip link set dev "$interface" down
      sleep 2
      ip link set dev "$interface" up
      sleep 10

      carrier=$(cat "$carrier_file")
      if [ "$carrier" = 1 ]; then
        echo "Carrier recovered on $interface after the interface cycle"
        rm -f "$first_down_file" "$last_attempt_file"
      else
        echo "Carrier remains down on $interface; another attempt is allowed after ${toString retryCooldownSeconds} seconds"
      fi
    '';
  };

  systemd.timers.vault-network-link-recovery = {
    description = "Periodically check Vault Ethernet carrier state";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "1min";
      AccuracySec = "10s";
      RandomizedDelaySec = "10s";
      Unit = "vault-network-link-recovery.service";
    };
  };
}
