{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ./modules/unpackerr.nix ];
  services.unpackerr = {
    enable = true;

    user = "plex";
    group = "plex";
    environmentFile = config.sops.secrets.unpackerr-env.path;

    # Look up default unpackerr config, its in toml format
    settings = {
      sonarr = [
        {
          url = "http://localhost:8989";
          protocols = "torrent";
          timeout = "100s";
        }
      ];

      radarr = [
        {
          url = "http://localhost:7878";
          protocols = "torrent";
          timeout = "100s";
        }
      ];
    };
  };
}
