{
  config,
  pkgs,
  ...
}:
let
  dataRoot = "/data/pinepods";
  networkName = "pinepods";
  pinepodsImage = "docker.io/madeofpendletonwool/pinepods:0.9.0@sha256:ebc258bb0c62cdb69e5fb726b247c885dac19b50d06fed68fa8d37197b88ace4";
  postgresImage = "docker.io/library/postgres:18.6-alpine@sha256:77f585114c32fbca283dc835b0596f4e52b51b4c6662d7810b2f4084f60a1873";
  valkeyImage = "docker.io/valkey/valkey:8.1.10-alpine@sha256:081c2f5cb575efc901aa80ff9cdbd1ec6a301682fd35e1ebb4b0990a4a4a8507";

  # The official image sources non-executable init scripts, so use its /bin/sh
  # and psql instead of referring to executables in the host Nix store.
  postgresInit = pkgs.writeText "pinepods-postgres-init.sh" ''
    #!/bin/sh
    set -eu

    psql \
      --set=ON_ERROR_STOP=1 \
      --username "$POSTGRES_USER" \
      --dbname "$POSTGRES_DB" <<'SQL'
    \getenv app_password PINEPODS_APP_PASSWORD
    SELECT format('CREATE ROLE pinepods LOGIN PASSWORD %L', :'app_password')
      WHERE NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'pinepods') \gexec
    ALTER DATABASE pinepods_database OWNER TO pinepods;
    SQL
  '';
in
{
  users = {
    users.pinepods = {
      isSystemUser = true;
      uid = 911;
      group = "pinepods";
      home = "${dataRoot}/downloads";
    };
    groups.pinepods.gid = 911;
  };

  sops.templates = {
    pinepods-postgres-env = {
      content = ''
        POSTGRES_PASSWORD=${config.sops.placeholder.pinepods-postgres-superuser-password}
        PINEPODS_APP_PASSWORD=${config.sops.placeholder.pinepods-db-password}
      '';
      mode = "0400";
    };
    pinepods-db-env = {
      content = ''
        DB_PASSWORD=${config.sops.placeholder.pinepods-db-password}
      '';
      mode = "0400";
    };
    pinepods-app-env = {
      content = ''
        PASSWORD=${config.sops.placeholder.pinepods-admin-password}
        OIDC_CLIENT_SECRET=${config.sops.placeholder.pinepods-oidc-client-secret}
      '';
      mode = "0400";
    };
  };

  virtualisation = {
    podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    oci-containers = {
      backend = "podman";
      containers = {
        pinepods-postgres = {
          image = postgresImage;
          networks = [ networkName ];
          environment = {
            POSTGRES_DB = "pinepods_database";
            POSTGRES_USER = "pinepods_owner";
            PGDATA = "/var/lib/pgdata/pgdata";
          };
          environmentFiles = [ config.sops.templates.pinepods-postgres-env.path ];
          volumes = [
            "${dataRoot}/postgres:/var/lib/pgdata"
            "${postgresInit}:/docker-entrypoint-initdb.d/10-pinepods-app.sh:ro"
          ];
        };

        pinepods-valkey = {
          image = valkeyImage;
          networks = [ networkName ];
          cmd = [
            "valkey-server"
            "--save"
            ""
            "--appendonly"
            "no"
          ];
        };

        pinepods = {
          image = pinepodsImage;
          networks = [ networkName ];
          dependsOn = [
            "pinepods-postgres"
            "pinepods-valkey"
          ];
          ports = [ "127.0.0.1:8040:8040" ];
          environment = {
            SEARCH_API_URL = "https://search.pinepods.online/api/search";
            PEOPLE_API_URL = "https://people.pinepods.online";
            HOSTNAME = "https://pods.basn.se";
            DB_TYPE = "postgresql";
            DB_HOST = "pinepods-postgres";
            DB_PORT = "5432";
            DB_USER = "pinepods";
            DB_NAME = "pinepods_database";
            VALKEY_HOST = "pinepods-valkey";
            VALKEY_PORT = "6379";
            DEBUG_MODE = "false";
            PUID = "911";
            PGID = "911";
            TZ = "Europe/Stockholm";
            DEFAULT_LANGUAGE = "en";
            FULLNAME = "Local recovery administrator";
            USERNAME = "basn-local";
            EMAIL = "basn-local@localhost.invalid";
            OIDC_DISABLE_STANDARD_LOGIN = "false";
            OIDC_PROVIDER_NAME = "Authentik";
            OIDC_CLIENT_ID = "pinepods";
            OIDC_AUTHORIZATION_URL = "https://auth.basn.se/application/o/authorize/";
            OIDC_TOKEN_URL = "https://auth.basn.se/application/o/token/";
            OIDC_USER_INFO_URL = "https://auth.basn.se/application/o/userinfo/";
            OIDC_BUTTON_TEXT = "Login with Authentik";
            OIDC_BUTTON_COLOR = "#1f2937";
            OIDC_BUTTON_TEXT_COLOR = "#ffffff";
            OIDC_SCOPE = "openid email profile";
            OIDC_NAME_CLAIM = "name";
            OIDC_EMAIL_CLAIM = "email";
            OIDC_USERNAME_CLAIM = "preferred_username";
            OIDC_ROLES_CLAIM = "";
            OIDC_USER_ROLE = "";
            OIDC_ADMIN_ROLE = "";
          };
          environmentFiles = [
            config.sops.templates.pinepods-db-env.path
            config.sops.templates.pinepods-app-env.path
          ];
          volumes = [
            "${dataRoot}/downloads:/opt/pinepods/downloads"
            "${dataRoot}/backups:/opt/pinepods/backups"
          ];
        };
      };
    };
  };

  systemd.services = {
    pinepods-storage = {
      description = "Initialize PinePods dataset permissions";
      wantedBy = [ "multi-user.target" ];
      before = [
        "podman-pinepods-postgres.service"
        "podman-pinepods.service"
      ];
      unitConfig.RequiresMountsFor = [
        dataRoot
        "${dataRoot}/postgres"
        "${dataRoot}/downloads"
        "${dataRoot}/backups"
      ];
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.coreutils}/bin/install -d -m 0700 -o 70 -g 70 "${dataRoot}/postgres"
        ${pkgs.coreutils}/bin/install -d -m 0750 -o pinepods -g pinepods \
          "${dataRoot}/downloads" "${dataRoot}/backups"
      '';
    };

    pinepods-network = {
      description = "PinePods Podman network";
      wantedBy = [ "multi-user.target" ];
      before = [
        "podman-pinepods-postgres.service"
        "podman-pinepods-valkey.service"
        "podman-pinepods.service"
      ];
      path = [ config.virtualisation.podman.package ];
      serviceConfig.Type = "oneshot";
      script = ''
        podman network create --ignore --driver bridge --subnet 10.92.0.0/24 ${networkName}
      '';
    };

    podman-pinepods-postgres = {
      requires = [
        "pinepods-network.service"
        "pinepods-storage.service"
      ];
      after = [
        "pinepods-network.service"
        "pinepods-storage.service"
      ];
    };
    podman-pinepods-valkey = {
      requires = [ "pinepods-network.service" ];
      after = [ "pinepods-network.service" ];
    };
    podman-pinepods = {
      requires = [
        "pinepods-network.service"
        "pinepods-storage.service"
      ];
      after = [
        "pinepods-network.service"
        "pinepods-storage.service"
      ];
      serviceConfig.EnvironmentFile = config.sops.templates.pinepods-db-env.path;
      preStart = ''
        export PGPASSWORD="$DB_PASSWORD"
        for attempt in $(${pkgs.coreutils}/bin/seq 1 60); do
          if ${config.virtualisation.podman.package}/bin/podman exec \
            --env PGPASSWORD pinepods-postgres \
            psql --host=127.0.0.1 --username=pinepods \
              --dbname=pinepods_database --no-password \
              --tuples-only --command='SELECT 1' >/dev/null 2>&1 \
            && ${config.virtualisation.podman.package}/bin/podman exec pinepods-valkey \
              valkey-cli ping >/dev/null 2>&1; then
            exit 0
          fi
          ${pkgs.coreutils}/bin/sleep 2
        done
        echo "PinePods database or Valkey did not become ready" >&2
        exit 1
      '';
    };

    pinepods-postgres-backup = {
      description = "Create a logical PinePods PostgreSQL backup";
      requires = [ "podman-pinepods-postgres.service" ];
      after = [ "podman-pinepods-postgres.service" ];
      unitConfig.RequiresMountsFor = [ "${dataRoot}/backups" ];
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = config.sops.templates.pinepods-db-env.path;
        UMask = "0077";
      };
      script = ''
        set -eu
        export PGPASSWORD="$DB_PASSWORD"
        timestamp="$(${pkgs.coreutils}/bin/date -u +%Y%m%dT%H%M%SZ)"
        output="${dataRoot}/backups/postgres-$timestamp.dump"
        temporary="$output.tmp"
        trap '${pkgs.coreutils}/bin/rm -f "$temporary"' EXIT

        ${config.virtualisation.podman.package}/bin/podman exec \
          --env PGPASSWORD pinepods-postgres \
          pg_dump --format=custom --clean --if-exists \
          --host=127.0.0.1 --username=pinepods --dbname=pinepods_database \
          --no-password > "$temporary"
        ${pkgs.coreutils}/bin/mv "$temporary" "$output"
        ${pkgs.findutils}/bin/find "${dataRoot}/backups" -maxdepth 1 \
          -type f -name 'postgres-*.dump' -mtime +14 -delete
      '';
    };
  };

  systemd.timers.pinepods-postgres-backup = {
    description = "Daily PinePods PostgreSQL backup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 03:20:00";
      Persistent = true;
      RandomizedDelaySec = "20m";
    };
  };
}
