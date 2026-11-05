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
        image = "ghcr.io/ozark-connect/network-optimizer:2.10.7@sha256:203e845b033e0a8dfa5ba831aeb521d6a1d0b1474356cfbd6c2f06281231cf58";
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
        image = "ghcr.io/ozark-connect/speedtest:2.10.7@sha256:49b32cc2873b52a9f8b7321dfbdb1a79f9da0c4f56bade29917701590b80d4bf";
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
