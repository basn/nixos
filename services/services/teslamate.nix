{ ... }:
{
  services = {
    teslamate = {
      enable = true;
      secretsFile = "/run/secrets/teslamate.env";
      autoStart = true;
      listenAddress = "127.0.0.1";
      port = 4000;
      virtualHost = "tesla.basn.se";
      urlPath = "/";
      postgres = {
        enable_server = true;
        user = "teslamate";
        database = "teslamate";
        host = "127.0.0.1";
        port = 5432;
      };
      grafana = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 3000;
        urlPath = "/";
      };
      mqtt = {
        enable = true;
        host = "127.0.0.1";
        port = 1883;
      };
    };
  };
}
