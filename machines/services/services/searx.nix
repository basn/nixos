{ ... }:
{
  services.searx = {
    enable = true;
    domain = "search.basn.se";
    configureNginx = true;
    environmentFile = "/run/secrets/searx";
    redisCreateLocally = true;
    settings = {
      server.secret_key = "$SEARX_SECRET_KEY";
      general.instance_name = "basn search";
    };
  };
}
