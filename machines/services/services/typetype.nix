{
  config,
  lib,
  pkgs,
  ...
}:
let
  typetypeSecrets = config.sops.secrets.typetype.path;
  typetypeDownloaderEnv = config.sops.templates.typetype-downloader-env.path;
  typetypeNginx = pkgs.writeText "typetype-nginx.conf" ''
    map $http_upgrade $connection_upgrade {
      default upgrade;
      ''' close;
    }

    resolver 10.89.0.1 valid=10s ipv6=off;

    upstream typetype_server_backend {
      zone typetype_server_backend 64k;
      server typetype-server:8080 resolve;
    }
    upstream typetype_token_backend {
      zone typetype_token_backend 64k;
      server typetype-token:8081 resolve;
    }
    upstream typetype_downloader_backend {
      zone typetype_downloader_backend 64k;
      server typetype-downloader:18093 resolve;
    }

    server {
      listen 80;
      root /usr/share/nginx/html;
      index index.html;
      client_max_body_size 2g;

      gzip on;
      gzip_types text/plain text/css application/javascript application/json image/svg+xml;

      location = /api/version {
        alias /usr/share/nginx/html/version.json;
        default_type application/json;
        add_header Cache-Control "no-cache";
      }
      location = /api/version/web {
        alias /usr/share/nginx/html/version-web.json;
        default_type application/json;
        add_header Cache-Control "no-cache";
      }
      location = /api/version/server {
        proxy_pass http://typetype_server_backend/version;
        add_header Cache-Control "no-cache";
      }
      location = /api/version/token {
        proxy_pass http://typetype_token_backend/version;
        add_header Cache-Control "no-cache";
      }
      location = /api/version/downloader {
        proxy_pass http://typetype_downloader_backend/version;
        add_header Cache-Control "no-cache";
      }
      location ^~ /api/ {
        proxy_pass http://typetype_server_backend/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 300;
        proxy_send_timeout 300;
        proxy_buffering off;
      }
      location ^~ /sabr/ {
        proxy_pass http://typetype_server_backend/sabr/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 300;
        proxy_send_timeout 300;
        proxy_buffering off;
      }
      location / {
        try_files $uri $uri/ /index.html;
      }
      location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
      }
    }
  '';
  garageConfig = pkgs.writeText "typetype-garage.toml" ''
    metadata_dir = "/var/lib/garage/meta"
    data_dir = "/var/lib/garage/data"
    db_engine = "sqlite"
    replication_factor = 1
    rpc_bind_addr = "[::]:3901"
    rpc_public_addr = "127.0.0.1:3901"

    [s3_api]
    s3_region = "garage"
    api_bind_addr = "[::]:3900"
  '';
in
{
  sops.templates.typetype-downloader-env = {
    content = ''
      S3_ACCESS_KEY=${config.sops.placeholder.typetype-s3-access-key}
      S3_SECRET_KEY=${config.sops.placeholder.typetype-s3-secret-key}
    '';
    mode = "0400";
  };

  systemd.tmpfiles.rules = [
    "d /docker/typetype 0750 root root - -"
    "d /docker/typetype/postgres 0750 root root - -"
    "d /docker/typetype/garage-meta 0750 root root - -"
    "d /docker/typetype/garage-data 0750 root root - -"
  ];

  systemd.services.typetype-network = {
    description = "TypeType Podman network";
    wantedBy = [ "multi-user.target" ];
    before = [
      "podman-typetype.service"
      "podman-typetype-server.service"
      "podman-typetype-token.service"
      "podman-typetype-downloader.service"
      "podman-typetype-postgres.service"
      "podman-typetype-dragonfly.service"
      "podman-typetype-garage.service"
    ];
    serviceConfig.Type = "oneshot";
    path = [ config.virtualisation.podman.package ];
    script = "podman network create --ignore --subnet 10.89.0.0/16 --gateway 10.89.0.1 typetype";
  };

  systemd.services.typetype-postgres-init = {
    description = "Initialize the TypeType downloader database";
    requiredBy = [
      "podman-typetype-server.service"
      "podman-typetype-downloader.service"
    ];
    requires = [ "podman-typetype-postgres.service" ];
    after = [ "podman-typetype-postgres.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [
      config.virtualisation.podman.package
      pkgs.gnugrep
    ];
    script = ''
      set -a
      . ${typetypeSecrets}
      set +a
      until podman exec -e PGPASSWORD="$POSTGRES_PASSWORD" typetype-postgres \
        pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"; do
        sleep 1
      done
      if ! podman exec -e PGPASSWORD="$POSTGRES_PASSWORD" typetype-postgres \
        psql -U typetype -d "$POSTGRES_DB" -tAc \
        "SELECT 1 FROM pg_database WHERE datname='typetype_downloader'" | grep -qx 1; then
        podman exec -e PGPASSWORD="$POSTGRES_PASSWORD" typetype-postgres \
          psql -U typetype -d "$POSTGRES_DB" -c \
          "CREATE DATABASE typetype_downloader"
      fi
    '';
  };

  systemd.services.typetype-garage-init = {
    description = "Provision TypeType download storage";
    requiredBy = [ "podman-typetype-downloader.service" ];
    requires = [ "podman-typetype-garage.service" ];
    after = [ "podman-typetype-garage.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [
      config.virtualisation.podman.package
      pkgs.gnugrep
    ];
    script = ''
      set -a
      . ${typetypeSecrets}
      set +a
      g() { podman exec typetype-garage /garage -c /etc/garage.toml "$@"; }
      until node_id=$(g node id | head -n1 | cut -d@ -f1); do
        sleep 1
      done
      if ! g layout show | grep -Eiq 'version:?[[:space:]]+[0-9]+'; then
        g layout assign -z dc1 -c 50GB "$node_id"
        g layout apply --version 1
      fi
      g bucket info typetype-downloads || g bucket create typetype-downloads
      if ! g key info "$DOWNLOADER_S3_ACCESS_KEY" >/dev/null 2>&1; then
        g key import --yes -n typetype-downloader \
          "$DOWNLOADER_S3_ACCESS_KEY" "$DOWNLOADER_S3_SECRET_KEY"
      fi
      g bucket allow --read --write --owner \
        --key "$DOWNLOADER_S3_ACCESS_KEY" typetype-downloads
    '';
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      typetype = {
        image = "ghcr.io/typetype-video/typetype:1.5.1@sha256:5d84f959d305134c389ac2ccd02ad4b6cfa9ba7f0d41a8532d089722510c7be0";
        networks = [ "typetype" ];
        ports = [ "127.0.0.1:18082:80" ];
        volumes = [ "${typetypeNginx}:/etc/nginx/conf.d/default.conf:ro" ];
        dependsOn = [ "typetype-server" ];
      };

      typetype-server = {
        image = "ghcr.io/typetype-video/typetype-server:1.5.1@sha256:e751be85309459990466cc10b45319bb91bbea7b333bf2894d58279def820963";
        networks = [ "typetype" ];
        environment = {
          ALLOWED_ORIGINS = "https://tube.basn.se";
          DATABASE_URL = "jdbc:postgresql://typetype-postgres:5432/typetype";
          DATABASE_USER = "typetype";
          DRAGONFLY_URL = "redis://typetype-dragonfly:6379";
          DOWNLOADER_SERVICE_URL = "http://typetype-downloader:18093";
          YOUTUBE_REMOTE_LOGIN_ENABLED = "false";
          YOUTUBE_REMOTE_LOGIN_SERVICE_URL = "http://typetype-token:8081";
          YOUTUBE_REMOTE_LOGIN_CALLBACK_BASE_URL = "http://typetype-server:8080";
          YOUTUBE_REMOTE_LOGIN_INTERNAL_TOKEN_FILE = "/run/typetype-secrets/youtube_remote_login_internal_token";
          YOUTUBE_SESSION_ENCRYPTION_KEY_FILE = "/run/typetype-secrets/youtube_session_encryption_key";
        };
        environmentFiles = [ typetypeSecrets ];
        volumes = [ "${typetypeSecrets}:/run/typetype-secrets:ro" ];
        dependsOn = [
          "typetype-postgres"
          "typetype-dragonfly"
          "typetype-token"
          "typetype-downloader"
        ];
      };

      typetype-downloader = {
        image = "ghcr.io/typetype-video/typetype-downloader:1.5.1@sha256:5d5fc287be07cdc280c6deef955a82c99ed3f87fa7caa41467242ea7b71ca48b";
        networks = [ "typetype" ];
        environment = {
          HTTP_PORT = "18093";
          PUBLIC_BASE_URL = "/api/downloader";
          TYPETYPE_API_BASE = "http://typetype-server:8080";
          REDIS_HOST = "typetype-dragonfly";
          REDIS_PORT = "6379";
          REDIS_QUEUE_KEY = "downloader:queue";
          MAX_CONCURRENT_WORKERS = "2";
          MAX_QUEUE_SIZE = "100";
          DOWNLOAD_WORKERS = "8";
          DOWNLOAD_CHUNK_SIZE = "10485760";
          DOWNLOAD_RANGE_MODE = "query";
          MUXER = "avformat";
          STORAGE_BACKEND = "s3";
          S3_ENDPOINT = "http://typetype-garage:3900";
          S3_PUBLIC_ENDPOINT = "http://typetype-garage:3900";
          S3_REGION = "garage";
          S3_BUCKET = "typetype-downloads";
          S3_ARTIFACT_TTL_SECONDS = "7200";
        };
        environmentFiles = [
          typetypeSecrets
          typetypeDownloaderEnv
        ];
        dependsOn = [
          "typetype-dragonfly"
          "typetype-garage"
          "typetype-token"
        ];
      };

      typetype-token = {
        image = "ghcr.io/typetype-video/typetype-token:1.5.1@sha256:5ef3b7f5d5402fb047b3069dd3e75337b17f78abffb489c1297984fb56827d6b";
        networks = [ "typetype" ];
        extraOptions = [ "--ipc=host" ];
        environment = {
          NODE_ENV = "production";
          YOUTUBE_REMOTE_LOGIN_ENABLED = "false";
          YOUTUBE_REMOTE_LOGIN_INTERNAL_TOKEN_FILE = "/run/typetype-secrets/youtube_remote_login_internal_token";
          YOUTUBE_REMOTE_LOGIN_CALLBACK_ORIGIN = "http://typetype-server:8080";
        };
        environmentFiles = [ typetypeSecrets ];
        volumes = [ "${typetypeSecrets}:/run/typetype-secrets:ro" ];
      };

      typetype-postgres = {
        image = "docker.io/library/postgres:17.10@sha256:7958605b474b3d264a969cb3a123d6aa00ad1e1fe9da8a69984dabb704d93317";
        networks = [ "typetype" ];
        environment = {
          POSTGRES_DB = "typetype";
          POSTGRES_USER = "typetype";
        };
        environmentFiles = [ typetypeSecrets ];
        volumes = [ "/docker/typetype/postgres:/var/lib/postgresql/data:U" ];
      };

      typetype-dragonfly = {
        image = "docker.dragonflydb.io/dragonflydb/dragonfly:v1.40.1@sha256:ebf3c6c213e82fb51b4521660cca13f06f3421dc5b1ed14f2f474c50b5e29986";
        networks = [ "typetype" ];
        extraOptions = [
          "--ulimit=memlock=-1"
          "--health-start-period=10s"
        ];
      };

      typetype-garage = {
        image = "docker.io/dxflrs/garage:v2.3.0@sha256:866bd13ed2038ba7e7190e840482bc27234c4afaf77be8cfa439ae088c1e4690";
        networks = [ "typetype" ];
        environmentFiles = [ typetypeSecrets ];
        volumes = [
          "${garageConfig}:/etc/garage.toml:ro"
          "/docker/typetype/garage-meta:/var/lib/garage/meta:U"
          "/docker/typetype/garage-data:/var/lib/garage/data:U"
        ];
      };
    };
  };

  systemd.services.podman-typetype = {
    requires = [ "typetype-network.service" ];
    after = [ "typetype-network.service" ];
  };

  systemd.services.podman-typetype-server = {
    requires = [
      "typetype-network.service"
      "typetype-postgres-init.service"
    ];
    after = [
      "typetype-network.service"
      "typetype-postgres-init.service"
    ];
  };

  systemd.services.podman-typetype-token = {
    requires = [ "typetype-network.service" ];
    after = [ "typetype-network.service" ];
  };

  systemd.services.podman-typetype-downloader = {
    requires = [
      "typetype-network.service"
      "typetype-garage-init.service"
      "typetype-postgres-init.service"
    ];
    after = [
      "typetype-network.service"
      "typetype-garage-init.service"
      "typetype-postgres-init.service"
    ];
  };

  systemd.services.podman-typetype-postgres = {
    requires = [ "typetype-network.service" ];
    after = [ "typetype-network.service" ];
  };

  systemd.services.podman-typetype-dragonfly = {
    requires = [ "typetype-network.service" ];
    after = [ "typetype-network.service" ];
  };

  systemd.services.podman-typetype-garage = {
    requires = [ "typetype-network.service" ];
    after = [ "typetype-network.service" ];
  };

  systemd.services.podman-container-refresh.script = lib.mkAfter ''
    systemctl restart \
      podman-typetype.service \
      podman-typetype-server.service \
      podman-typetype-token.service \
      podman-typetype-downloader.service \
      podman-typetype-postgres.service \
      podman-typetype-dragonfly.service \
      podman-typetype-garage.service
  '';
}
