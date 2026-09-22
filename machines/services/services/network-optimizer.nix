{ pkgs, ... }:
{
  systemd.tmpfiles.rules = [
    "d /docker/networkoptimizer 0750 root root - -"
    "d /docker/networkoptimizer/data 0750 root root - -"
    "d /docker/networkoptimizer/logs 0750 root root - -"
    "d /docker/networkoptimizer/ssh-keys 0700 root root - -"
    "d /docker/networkoptimizer/speedtest 0750 root root - -"
  ];

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      networkoptimizer = {
        image = "ghcr.io/ozark-connect/network-optimizer:2.8.6@sha256:c796251214f6cf2bef31b811c8743768c387eb2daf7e56d2b5fd940d50339735";
        autoStart = true;
        extraOptions = [ "--network=host" ];
        environment = {
          TZ = "Europe/Stockholm";
          BIND_LOCALHOST_ONLY = "true";
          OPENSPEEDTEST_PORT = "3005";
          PING_INTERVAL = "180";
          ENABLE_PERSISTENCE = "true";
          LOG_LEVEL = "Information";
        };
        volumes = [
          "/docker/networkoptimizer/data:/app/data"
          "/docker/networkoptimizer/logs:/app/logs"
          "/docker/networkoptimizer/ssh-keys:/app/ssh-keys:ro"
        ];
      };

      speedtest = {
        image = "ghcr.io/ozark-connect/speedtest:2.8.6@sha256:f10bb553bb05cf27946c7a702b7ad43ed24b0b02c5737f4b8c7ec7bb0762a5f9";
        autoStart = true;
        ports = [ "127.0.0.1:3005:3000" ];
        environment = {
          TZ = "Europe/Stockholm";
          OPENSPEEDTEST_PORT = "3005";
        };
        volumes = [ "/docker/networkoptimizer/speedtest:/config" ];
      };
    };
  };

  systemd.timers.podman-container-refresh = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };

  systemd.services.podman-container-refresh = {
    serviceConfig.Type = "oneshot";
    script = ''
      systemctl restart podman-networkoptimizer.service podman-speedtest.service podman-redbot.service
    '';
  };
}
