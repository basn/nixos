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
        image = "docker.io/phasecorex/red-discordbot:latest@sha256:1003f768ae1669a1fb227e7b5e0e4863f2b4d0c1564977015d8e947719a1e26b";
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "/docker/redbot/:/data"
        ];
      };
    };
  };
}
