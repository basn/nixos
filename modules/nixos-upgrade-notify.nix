{
  options,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.basn.nixosUpgradeNotify;
  defaultWebhookSecretFile = ../secrets/webhook.yaml;
  hasSops = options ? sops && builtins.pathExists defaultWebhookSecretFile;
  webhookIdArg =
    if cfg.webhookIdFile != null then
      "$(tr -d '[:space:]' < ${lib.escapeShellArg cfg.webhookIdFile})"
    else
      lib.escapeShellArg cfg.webhookId;

  notifyScript = pkgs.writeShellScript "nixos-upgrade-notify" ''
    set -u

    status="$1"
    unit="''${2:-nixos-upgrade.service}"
    webhook_id=${webhookIdArg}
    webhook_url=${lib.escapeShellArg cfg.homeAssistantUrl}/api/webhook/"$webhook_id"
    system_link="$(readlink -f /nix/var/nix/profiles/system 2>/dev/null || true)"
    generation="$(basename "$(readlink /nix/var/nix/profiles/system 2>/dev/null || true)" | sed -n 's/^system-\([0-9]\+\)-link$/\1/p')"
    nixos_version="$(/run/current-system/sw/bin/nixos-version 2>/dev/null || true)"

    if [ "$status" = "failure" ]; then
      message="NixOS upgrade failed on ${config.networking.hostName}"
      journal="$(journalctl -u "$unit" -n ${toString cfg.failureJournalLines} --no-pager --output=cat 2>/dev/null || true)"
    else
      message="NixOS upgraded on ${config.networking.hostName}"
      journal=""
    fi

    payload="$(
      jq -n \
        --arg event "nixos_upgrade" \
        --arg status "$status" \
        --arg host ${lib.escapeShellArg config.networking.hostName} \
        --arg unit "$unit" \
        --arg generation "$generation" \
        --arg system "$system_link" \
        --arg version "$nixos_version" \
        --arg message "$message" \
        --arg journal "$journal" \
        '{
          event: $event,
          status: $status,
          host: $host,
          unit: $unit,
          generation: $generation,
          system: $system,
          version: $version,
          message: $message,
          journal: $journal
        }'
    )"

    curl \
      --fail \
      --silent \
      --show-error \
      --max-time ${toString cfg.timeoutSec} \
      --header 'Content-Type: application/json' \
      --data "$payload" \
      "$webhook_url"
  '';
in
{
  options.basn.nixosUpgradeNotify = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.system.autoUpgrade.enable;
      description = "Whether to notify Home Assistant about automatic NixOS upgrade status.";
    };

    homeAssistantUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://hass.basn.se";
      description = "Base URL for Home Assistant.";
    };

    webhookId = lib.mkOption {
      type = lib.types.str;
      default = "nixos-upgrade";
      description = "Home Assistant webhook ID used when webhookIdFile is not set.";
    };

    webhookIdFile = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.oneOf [
          lib.types.path
          lib.types.str
        ]
      );
      default = if cfg.enable && hasSops then config.sops.secrets.nixos-upgrade-webhook.path else null;
      description = "Optional file containing the Home Assistant webhook ID.";
    };

    timeoutSec = lib.mkOption {
      type = lib.types.ints.positive;
      default = 10;
      description = "Maximum time to wait for Home Assistant webhook requests.";
    };

    failureJournalLines = lib.mkOption {
      type = lib.types.ints.positive;
      default = 40;
      description = "Number of nixos-upgrade journal lines to include in failure events.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && hasSops) {
      sops.secrets.nixos-upgrade-webhook = {
        sopsFile = defaultWebhookSecretFile;
        key = "nixos-upgrade-webhook";
      };
    })

    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = config.system.autoUpgrade.enable;
          message = "basn.nixosUpgradeNotify.enable requires system.autoUpgrade.enable = true.";
        }
      ];

      systemd.services.nixos-upgrade = {
        unitConfig.OnFailure = [ "nixos-upgrade-notify-failure.service" ];
        path = with pkgs; [
          coreutils
          curl
          gnused
          jq
          systemd
        ];
        preStart = ''
          mkdir -p /run/nixos-upgrade-notify
          readlink -f /nix/var/nix/profiles/system > /run/nixos-upgrade-notify/previous-system 2>/dev/null || true
        '';
        postStart = ''
          previous_system="$(cat /run/nixos-upgrade-notify/previous-system 2>/dev/null || true)"
          current_system="$(readlink -f /nix/var/nix/profiles/system 2>/dev/null || true)"

          if [ -n "$current_system" ] && [ "$current_system" != "$previous_system" ]; then
            ${notifyScript} success nixos-upgrade.service || true
          fi
        '';
      };

      systemd.services.nixos-upgrade-notify-failure = {
        description = "Notify Home Assistant about failed NixOS upgrade";
        wantedBy = [ ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        path = with pkgs; [
          coreutils
          curl
          gnused
          jq
          systemd
        ];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          ${notifyScript} failure nixos-upgrade.service || true
        '';
      };

      systemd.services.nixos-upgrade-notify-success = {
        description = "Notify Home Assistant about successful NixOS upgrade";
        wantedBy = [ ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        path = with pkgs; [
          coreutils
          curl
          gnused
          jq
          systemd
        ];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          ${notifyScript} success nixos-upgrade.service || true
        '';
      };
    })
  ];
}
