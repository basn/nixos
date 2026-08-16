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
        image = "docker.io/phasecorex/red-discordbot@sha256:034aba0c83961a20b00a5318696d3bbdacfb00958154ff52c1d6705fb36cf64f";
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "/docker/redbot/:/data"
        ];
      };
    };
  };
}
