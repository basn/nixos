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
        image = "ghcr.io/ozark-connect/network-optimizer:2.9.3@sha256:f5df414ba35d6a9f798e1d3039e7fd832ba5a61169de63e8ed2740b9ea75395a";
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
        image = "ghcr.io/ozark-connect/speedtest:2.9.3@sha256:8bd2ac0a60347e050cb81d3d1e1bf8007332df5835a1b3aec25b8ec06de9a7df";
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
