{ config, ... }:
let
  authentikSecrets = config.sops.secrets.authentik.path;
  authentikImage = "ghcr.io/goauthentik/server:2026.8.1@sha256:d670ebbf308212c0c971649c4beb903bb7e0bc7fb0ec08b7fc78faa9188846da";
in
{
  # Use the upstream images so flake updates do not build Authentik's Node/V8
  # web assets locally.  The native PostgreSQL 14 data remains untouched as a
  # rollback source; the restore unit imports its pre-cutover dump once.
  systemd.tmpfiles.rules = [
    "d /docker/authentik 0750 root root - -"
    "d /docker/authentik/backups 0700 root root - -"
    # PostgreSQL's container user is UID 999. Keep the bind-mount root
    # accessible to it across activation, rather than resetting it to root.
    "d /docker/authentik/postgres 0700 999 root - -"
    "d /docker/authentik/redis 0700 root root - -"
    "d /docker/authentik/media 0750 root root - -"
  ];

  systemd.services.authentik-network = {
    description = "Authentik Podman network";
    wantedBy = [ "multi-user.target" ];
    before = [
      "podman-authentik-postgres.service"
      "podman-authentik-redis.service"
      "podman-authentik-server.service"
      "podman-authentik-worker.service"
    ];
    path = [ config.virtualisation.podman.package ];
    serviceConfig.Type = "oneshot";
    script = "podman network create --ignore authentik";
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      authentik-postgres = {
        image = "docker.io/library/postgres:17.11@sha256:a65e6a841f6c4dbc4abda3d67fa3bc21824e9611064fcd82e87ea67aad60a0c3";
        networks = [ "authentik" ];
        environment = {
          POSTGRES_DB = "authentik";
          POSTGRES_USER = "authentik";
        };
        environmentFiles = [ authentikSecrets ];
        volumes = [ "/docker/authentik/postgres:/var/lib/postgresql/data:U" ];
      };

      authentik-redis = {
        image = "docker.io/library/redis:7.4.10-alpine@sha256:e7723ff73d963f5cc6d9c4643ea3d989527a402a319239054e9472a7fb9219a2";
        networks = [ "authentik" ];
        cmd = [
          "redis-server"
          "--appendonly"
          "yes"
          "--save"
          "60"
          "1"
        ];
        volumes = [ "/docker/authentik/redis:/data:U" ];
      };

      authentik-server = {
        image = authentikImage;
        cmd = [ "server" ];
        networks = [ "authentik" ];
        dependsOn = [
          "authentik-postgres"
          "authentik-redis"
        ];
        ports = [
          "127.0.0.1:9000:9000"
          "127.0.0.1:9443:9443"
        ];
        environment = {
          AUTHENTIK_AVATARS = "initials";
          AUTHENTIK_DISABLE_STARTUP_ANALYTICS = "true";
          AUTHENTIK_EMAIL__FROM = "authentik@basn.se";
          AUTHENTIK_EMAIL__HOST = "virtmx.lan2k.org";
          AUTHENTIK_EMAIL__PORT = "587";
          AUTHENTIK_EMAIL__USERNAME = "authentik@basn.se";
          AUTHENTIK_EMAIL__USE_SSL = "false";
          AUTHENTIK_EMAIL__USE_TLS = "true";
          AUTHENTIK_LISTEN__HTTP = "0.0.0.0:9000";
          AUTHENTIK_LISTEN__HTTPS = "0.0.0.0:9443";
          AUTHENTIK_POSTGRESQL__HOST = "authentik-postgres";
          AUTHENTIK_POSTGRESQL__NAME = "authentik";
          AUTHENTIK_POSTGRESQL__PASSWORD = "env://POSTGRES_PASSWORD";
          AUTHENTIK_POSTGRESQL__USER = "authentik";
          AUTHENTIK_REDIS__HOST = "authentik-redis";
        };
        environmentFiles = [ authentikSecrets ];
        volumes = [ "/docker/authentik/media:/media:U" ];
      };

      authentik-worker = {
        image = authentikImage;
        cmd = [ "worker" ];
        networks = [ "authentik" ];
        dependsOn = [
          "authentik-postgres"
          "authentik-redis"
        ];
        environment = {
          AUTHENTIK_AVATARS = "initials";
          AUTHENTIK_DISABLE_STARTUP_ANALYTICS = "true";
          AUTHENTIK_EMAIL__FROM = "authentik@basn.se";
          AUTHENTIK_EMAIL__HOST = "virtmx.lan2k.org";
          AUTHENTIK_EMAIL__PORT = "587";
          AUTHENTIK_EMAIL__USERNAME = "authentik@basn.se";
          AUTHENTIK_EMAIL__USE_SSL = "false";
          AUTHENTIK_EMAIL__USE_TLS = "true";
          AUTHENTIK_POSTGRESQL__HOST = "authentik-postgres";
          AUTHENTIK_POSTGRESQL__NAME = "authentik";
          AUTHENTIK_POSTGRESQL__PASSWORD = "env://POSTGRES_PASSWORD";
          AUTHENTIK_POSTGRESQL__USER = "authentik";
          AUTHENTIK_REDIS__HOST = "authentik-redis";
        };
        environmentFiles = [ authentikSecrets ];
        volumes = [ "/docker/authentik/media:/media:U" ];
      };
    };
  };

  systemd.services.podman-authentik-postgres = {
    requires = [ "authentik-network.service" ];
    after = [ "authentik-network.service" ];
  };
  systemd.services.podman-authentik-redis = {
    requires = [ "authentik-network.service" ];
    after = [ "authentik-network.service" ];
  };
  systemd.services.podman-authentik-server = {
    requires = [ "authentik-network.service" ];
    after = [ "authentik-network.service" ];
  };
  systemd.services.podman-authentik-worker = {
    requires = [ "authentik-network.service" ];
    after = [ "authentik-network.service" ];
  };
}
