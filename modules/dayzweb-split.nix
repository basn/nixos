{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.dayzwebSplit;
  python = pkgs.python313.withPackages (
    ps: with ps; [
      aiohttp
      fastapi
      jinja2
      pydantic
      python-multipart
      uvicorn
    ]
  );
  tokenSopsFile = ../secrets/dayzweb-ingest-token.yaml;
  tokenProvisioned = builtins.pathExists tokenSopsFile;
  tokenCredentialPath = "/run/secrets/dayzweb-ingest-token";
  anyEnabled = cfg.ingest.enable || cfg.worker.enable;
  hardening = {
    CapabilityBoundingSet = "";
    DevicePolicy = "closed";
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    NoNewPrivileges = true;
    PrivateDevices = true;
    PrivateTmp = true;
    ProtectClock = true;
    ProtectControlGroups = true;
    ProtectHome = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectProc = "invisible";
    ProtectSystem = "strict";
    RestrictAddressFamilies = [
      "AF_UNIX"
      "AF_INET"
      "AF_INET6"
    ];
    RestrictNamespaces = true;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    SystemCallArchitectures = "native";
    UMask = "0077";
  };
in
{
  options.services.dayzwebSplit = {
    sourcePath = lib.mkOption {
      type = lib.types.strMatching "^/.*";
      description = "Mutable deployed DayZWeb source path.";
    };
    user = lib.mkOption {
      type = lib.types.str;
      description = "Existing unprivileged DayZWeb service account.";
    };
    netbirdUnits = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Evaluated NetBird systemd units required by DayZWeb.";
    };
    ingest = {
      enable = lib.mkEnableOption "the DayZWeb internal ingest API";
      listenAddress = lib.mkOption {
        type = lib.types.str;
        description = "Services host NetBird address; wildcard addresses are rejected.";
      };
      port = lib.mkOption {
        type = lib.types.port;
        description = "Private ingest TCP port.";
      };
      database = lib.mkOption {
        type = lib.types.strMatching "^/.*";
        description = "SQLite database path on the services host.";
      };
      tokenCredentialPath = lib.mkOption {
        type = lib.types.strMatching "^/.*";
        default = tokenCredentialPath;
        readOnly = true;
        description = "SOPS-provisioned runtime token path outside the Nix store.";
      };
    };
    worker = {
      enable = lib.mkEnableOption "the DayZWeb Aftermath collection worker";
      ingestUrl = lib.mkOption {
        type = lib.types.str;
        description = "NetBird URL of the services ingest API.";
      };
      serverId = lib.mkOption {
        type = lib.types.str;
        description = "Aftermath server identifier.";
      };
      detailConcurrency = lib.mkOption {
        type = lib.types.ints.between 1 64;
        default = 8;
        description = "Maximum concurrent Aftermath detail requests.";
      };
      tokenCredentialPath = lib.mkOption {
        type = lib.types.strMatching "^/.*";
        default = tokenCredentialPath;
        readOnly = true;
        description = "SOPS-provisioned runtime token path outside the Nix store.";
      };
      onCalendar = lib.mkOption {
        type = lib.types.str;
        default = "hourly";
        description = "systemd OnCalendar expression for collection.";
      };
      timeoutStartSec = lib.mkOption {
        type = lib.types.str;
        default = "infinity";
        description = "Worker startup timeout.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf anyEnabled {
      assertions = [
        {
          assertion =
            !cfg.ingest.enable
            || !builtins.elem cfg.ingest.listenAddress [
              "0.0.0.0"
              "::"
            ];
          message = "services.dayzwebSplit.ingest.listenAddress must not be a wildcard address.";
        }
      ];

      warnings = lib.optional (!tokenProvisioned) ''
        DayZWeb split collection is blocked because secrets/dayzweb-ingest-token.yaml is absent.
        Follow docs/dayzweb-split-deployment.md to provision the shared SOPS secret before deployment.
      '';

      sops.secrets = lib.optionalAttrs tokenProvisioned {
        dayzweb-ingest-token = {
          sopsFile = tokenSopsFile;
          key = "token";
          mode = "0400";
          restartUnits =
            lib.optionals cfg.ingest.enable [ "dayzweb-ingest.service" ]
            ++ lib.optionals cfg.worker.enable [ "dayzweb-collector.service" ];
        };
      };
    })

    (lib.mkIf cfg.ingest.enable {
      systemd.services.dayzweb-ingest = {
        description = "DayZWeb private collection ingest API";
        wantedBy = lib.optionals tokenProvisioned [ "multi-user.target" ];
        after = [ "network-online.target" ] ++ cfg.netbirdUnits;
        wants = [ "network-online.target" ];
        requires = cfg.netbirdUnits;
        environment = {
          DAYZWEB_DATABASE = cfg.ingest.database;
          PYTHONPATH = cfg.sourcePath;
        };
        unitConfig = {
          ConditionPathExists = [
            "${cfg.sourcePath}/app/ingest.py"
            cfg.ingest.tokenCredentialPath
          ];
          RequiresMountsFor = [ cfg.ingest.database ];
        };
        serviceConfig = hardening // {
          User = cfg.user;
          Group = cfg.user;
          StateDirectory = "dayzweb";
          StateDirectoryMode = "0750";
          WorkingDirectory = cfg.sourcePath;
          ExecStart = lib.escapeShellArgs [
            "${python}/bin/uvicorn"
            "--factory"
            "app.ingest:create_app"
            "--host"
            cfg.ingest.listenAddress
            "--port"
            (toString cfg.ingest.port)
            "--workers"
            "1"
          ];
          LoadCredential = "ingest-token:${cfg.ingest.tokenCredentialPath}";
          ReadOnlyPaths = [ cfg.sourcePath ];
          ReadWritePaths = [ (builtins.dirOf cfg.ingest.database) ];
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
    })

    (lib.mkIf cfg.worker.enable {
      systemd.services.dayzweb-collector = {
        description = "DayZWeb Aftermath collection worker";
        after = [ "network-online.target" ] ++ cfg.netbirdUnits;
        wants = [ "network-online.target" ];
        requires = cfg.netbirdUnits;
        environment = {
          DAYZWEB_DETAIL_CONCURRENCY = toString cfg.worker.detailConcurrency;
          DAYZWEB_INGEST_URL = cfg.worker.ingestUrl;
          DAYZWEB_SERVER_ID = cfg.worker.serverId;
          PYTHONPATH = cfg.sourcePath;
        };
        unitConfig.ConditionPathExists = [
          "${cfg.sourcePath}/app/collector.py"
          cfg.worker.tokenCredentialPath
        ];
        serviceConfig = hardening // {
          Type = "oneshot";
          User = cfg.user;
          Group = cfg.user;
          WorkingDirectory = cfg.sourcePath;
          ExecStart = lib.escapeShellArgs [
            "${python}/bin/python"
            "-m"
            "app.collector"
          ];
          LoadCredential = "ingest-token:${cfg.worker.tokenCredentialPath}";
          ReadOnlyPaths = [ cfg.sourcePath ];
          TimeoutStartSec = cfg.worker.timeoutStartSec;
        };
      };

      systemd.timers.dayzweb-collector = {
        wantedBy = lib.optionals tokenProvisioned [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.worker.onCalendar;
          Persistent = true;
          Unit = "dayzweb-collector.service";
        };
      };
    })
  ];
}
