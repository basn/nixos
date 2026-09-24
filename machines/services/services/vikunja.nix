{
  config,
  lib,
  ...
}:
let
  credentialDirectory = "$CREDENTIALS_DIRECTORY";
in
{
  fileSystems."/var/lib/vikunja" = {
    device = "tank/vikunja";
    fsType = "zfs";
  };

  users = {
    users.vikunja = {
      isSystemUser = true;
      group = "vikunja";
      home = "/var/lib/vikunja";
    };
    groups.vikunja = { };
  };

  services.vikunja = {
    enable = true;
    address = "127.0.0.1";
    port = 3456;
    frontendScheme = "https";
    frontendHostname = "vikunja.basn.se";
    database = {
      type = "sqlite";
      path = "/var/lib/vikunja/vikunja.db";
    };
    settings = {
      service = {
        secret.file = "${credentialDirectory}/service-secret";
        rootpath = "/var/lib/vikunja";
        enablecaldav = false;
        enablelinksharing = false;
        enableregistration = false;
        enableemailreminders = false;
        enablepublicteams = false;
        ipextractionmethod = "xff";
        trustedproxies = "127.0.0.1/32";
      };
      auth = {
        local.enabled = false;
        openid = {
          enabled = true;
          providers.authentik = {
            name = "Authentik";
            authurl = "https://auth.basn.se/application/o/vikunja/";
            clientid = "vikunja";
            clientsecret.file = "${credentialDirectory}/oidc-client-secret";
            scope = "openid profile email";
            emailfallback = false;
            usernamefallback = false;
            forceuserinfo = false;
            requireavailability = true;
          };
        };
      };
      mailer.enabled = false;
      defaultsettings = {
        email_reminders_enabled = false;
        overdue_tasks_reminders_enabled = false;
      };
      files = {
        type = "local";
        maxsize = "20MB";
      };
      migration = {
        maxcsvrows = 10000;
        vikunjafile = {
          maxsize = "20MB";
          maxfiles = 1000;
          maxuserstorage = "256MB";
        };
        todoist.enable = false;
        trello.enable = false;
        microsofttodo.enable = false;
      };
      ratelimit = {
        enabled = true;
        kind = "user";
        period = 60;
        limit = 100;
        store = "memory";
        noauthlimit = 10;
        tokenrefreshlimit = 60;
        basicauthlimit = 10;
      };
      sentry = {
        enabled = false;
        frontendenabled = false;
      };
      backgrounds.providers.unsplash.enabled = false;
      plugins.enabled = false;
    };
  };

  systemd.services.vikunja = {
    after = [
      "network-online.target"
      "nginx.service"
      "podman-authentik-server.service"
    ];
    wants = [
      "network-online.target"
      "nginx.service"
      "podman-authentik-server.service"
    ];
    unitConfig.RequiresMountsFor = [ "/var/lib/vikunja" ];
    serviceConfig = {
      # A static account keeps StateDirectory on the ZFS mount instead of
      # DynamicUser's /var/lib/private indirection.
      DynamicUser = lib.mkForce false;
      User = "vikunja";
      Group = "vikunja";
      StateDirectoryMode = "0750";
      LoadCredential = [
        "service-secret:${config.sops.secrets.vikunja-service-secret.path}"
        "oidc-client-secret:${config.sops.secrets.vikunja-oidc-client-secret.path}"
      ];
      UMask = "0077";
      CapabilityBoundingSet = "";
      LockPersonality = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectSystem = "strict";
      RestrictSUIDSGID = true;
    };
  };
}
