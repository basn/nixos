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
        image = "docker.io/phasecorex/red-discordbot@sha256:982123f068ed95892a111c04fe05222952c5a6811a6ed6d1a7cd20c67e618df2";
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "/docker/redbot/:/data"
        ];
      };
    };
  };
}
