{
  config,
  lib,
  pkgs,
  ...
}:
let
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
  environment = {
    DAYZWEB_DATABASE = "/var/lib/dayzweb/dayzweb.sqlite3";
    DAYZWEB_SERVER_ID = "1ed9f69d-4ee3-6dac-b18b-ea5e938a80e2";
    DAYZWEB_ADMIN_USERNAME = "basn";
    DAYZWEB_TIMEZONE = "Europe/Stockholm";
  };
in
{
  imports = [ ../../../modules/dayzweb-split.nix ];

  users.users.dayzweb = {
    isSystemUser = true;
    group = "dayzweb";
  };
  users.groups.dayzweb = { };

  systemd.tmpfiles.rules = [
    "d /srv/dayzweb 0755 root root -"
    "d /srv/dayzweb/releases 0755 root root -"
  ];

  systemd.services.dayzweb = {
    description = "DayZ historical scoreboard web application";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network-online.target"
      "var-lib-dayzweb.mount"
    ];
    wants = [ "network-online.target" ];
    requires = [ "var-lib-dayzweb.mount" ];
    inherit environment;
    serviceConfig = {
      User = "dayzweb";
      Group = "dayzweb";
      StateDirectory = "dayzweb";
      WorkingDirectory = "/srv/dayzweb/current";
      ExecStart = "${python}/bin/uvicorn app.main:app --host 127.0.0.1 --port 18110";
      Restart = "on-failure";
      RestartSec = "5s";
      CapabilityBoundingSet = "";
      DevicePolicy = "closed";
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
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
      ReadOnlyPaths = [ "/srv/dayzweb" ];
      ReadWritePaths = [ "/var/lib/dayzweb" ];
      NoNewPrivileges = true;
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
    unitConfig.ConditionPathExists = "/srv/dayzweb/current/app/main.py";
  };

  services.dayzwebSplit = {
    sourcePath = "/srv/dayzweb/current";
    user = "dayzweb";
    netbirdUnits = [ "netbird.service" ];
    ingest = {
      enable = true;
      listenAddress = "100.86.89.177";
      port = 18111;
      database = environment.DAYZWEB_DATABASE;
    };
  };

  networking.firewall.extraInputRules = lib.mkAfter ''
    iifname "wt0" ip saddr 100.86.229.241 tcp dport 18111 accept
  '';
}
