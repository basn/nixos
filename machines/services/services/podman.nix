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
        image = "docker.io/phasecorex/red-discordbot@sha256:30eec16a72b307996f08e3f8bbf130436c3d437d7e797f16c47b4d1978d6e0d3";
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "/docker/redbot/:/data"
        ];
      };
    };
  };
}
