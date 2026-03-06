{ pkgs, ... }:
{
  systemd.tmpfiles.rules = [
    "d /docker/networkoptimizer 0750 root root - -"
    "d /docker/networkoptimizer/data 0750 root root - -"
    "d /docker/networkoptimizer/logs 0750 root root - -"
    "d /docker/networkoptimizer/ssh-keys 0700 root root - -"
    "d /docker/networkoptimizer/speedtest 0750 root root - -"
  ];

  systemd.services.pod-networkoptimizer = {
    description = "Podman pod for NetworkOptimizer";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.podman ];
    script = ''
      if ! podman pod exists networkoptimizer; then
        podman pod create \
          --name networkoptimizer \
          --network host
      fi
    '';
    preStop = ''
      podman pod rm -f networkoptimizer || true
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      networkoptimizer = {
        image = "ghcr.io/ozark-connect/network-optimizer:latest";
        autoStart = true;
        extraOptions = [ "--pod=networkoptimizer" ];
        environment = {
          TZ = "Europe/Stockholm";
          APP_PORT = "8042";
          EXTERNAL_PORT = "8042";
          PING_INTERVAL = "180";
          ENABLE_PERSISTENCE = "true";
          LOG_LEVEL = "info";
        };
        volumes = [
          "/docker/networkoptimizer/data:/app/data"
          "/docker/networkoptimizer/logs:/app/logs"
          "/docker/networkoptimizer/ssh-keys:/app/ssh-keys"
        ];
      };

      speedtest = {
        image = "ghcr.io/ozark-connect/speedtest:latest";
        autoStart = true;
        extraOptions = [ "--pod=networkoptimizer" ];
        environment = {
          TZ = "Europe/Stockholm";
        };
        volumes = [ "/docker/networkoptimizer/speedtest:/config" ];
      };
    };
  };

  systemd.services.podman-networkoptimizer = {
    requires = [ "pod-networkoptimizer.service" ];
    after = [ "pod-networkoptimizer.service" ];
  };

  systemd.services.podman-speedtest = {
    requires = [ "pod-networkoptimizer.service" ];
    after = [ "pod-networkoptimizer.service" ];
  };
}
