{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ podman ];
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
        # Upstream publishes this image from its unversioned master branch.
        image = "docker.io/phasecorex/red-discordbot:latest@sha256:45282c6396df894e3613bfca6af819eca59316051c1b891052cae51cef4dc314";
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "/docker/redbot/:/data"
        ];
      };
    };
  };
}
