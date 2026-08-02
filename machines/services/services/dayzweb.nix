{ pkgs, ... }:
let
  python = pkgs.python313.withPackages (
    ps: with ps; [
      aiohttp
      fastapi
      jinja2
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
      ProtectSystem = "strict";
      ReadOnlyPaths = [ "/srv/dayzweb" ];
      ReadWritePaths = [ "/var/lib/dayzweb" ];
      NoNewPrivileges = true;
    };
    unitConfig.ConditionPathExists = "/srv/dayzweb/current/app/main.py";
  };

  systemd.services.dayzweb-collect = {
    description = "Collect DayZ scoreboard snapshot";
    after = [
      "network-online.target"
      "var-lib-dayzweb.mount"
    ];
    wants = [ "network-online.target" ];
    requires = [ "var-lib-dayzweb.mount" ];
    inherit environment;
    serviceConfig = {
      Type = "oneshot";
      User = "dayzweb";
      Group = "dayzweb";
      StateDirectory = "dayzweb";
      WorkingDirectory = "/srv/dayzweb/current";
      ExecStart = "${python}/bin/python -m app.collector";
      ProtectSystem = "strict";
      ReadOnlyPaths = [ "/srv/dayzweb" ];
      ReadWritePaths = [ "/var/lib/dayzweb" ];
      NoNewPrivileges = true;
    };
    unitConfig.ConditionPathExists = "/srv/dayzweb/current/app/main.py";
  };

  systemd.timers.dayzweb-collect = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
      Unit = "dayzweb-collect.service";
    };
  };
}
