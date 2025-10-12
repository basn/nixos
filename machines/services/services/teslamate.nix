{ ... }:
{
  services = {
    teslamate = {
      enable = false;
      secretsFile = "/run/secrets/teslamate";
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
        enable = false;
        listenAddress = "127.0.0.1";
        port = 3000;
        urlPath = "/";
      };
      mqtt = {
        enable = false;
        host = "127.0.0.1";
        port = 1883;
      };
    };
  };
}
