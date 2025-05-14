{ config, ...}:
{
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
      defaultNetwork = {
        settings = {
          dns_enabled = true;
	};
      };
    };
  };
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      redbot = {
        image = "phasecorex/red-discordbot";
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "/docker/redbot/:/data"
        ];
      };
      unifi = { 
        image = "jacobalberty/unifi:latest";
        ports = [ 
          "9080:8080"
          "9443:8443"
          "3478:3478/udp"
          "10001:10001/udp"
        ];
        volumes = [
          "/docker/unifi:/unifi"
        ];
        environment = {
          TZ = "Europe/Stockholm";
          RUNAS_UID0 = "true";
        };
      };
    };
  };
}
