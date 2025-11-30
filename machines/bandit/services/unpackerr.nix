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

    # Look up default unpackerr config, its in toml format
    settings = {
      sonarr = [
        {
          url = "http://localhost:8989";
          protocols = "torrent";
          timeout = "100s";
          api_key = "15fdb9c5b1ff46bd88925e186e5bc35f";
        }
      ];

      radarr = [
        {
          url = "http://localhost:7878";
          protocols = "torrent";
          timeout = "100s";
          api_key = "5744a4901ee4459fab14c50469fa686e";
        }
      ];
    };
  };
}
