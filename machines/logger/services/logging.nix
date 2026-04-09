{
  config,
  lib,
  ...
}:
{
  services.mongodb = {
    enable = true;
    bind_ip = "127.0.0.1";
  };

  services.opensearch = {
    enable = true;
    settings = {
      "cluster.name" = "graylog";
      "node.name" = "logger";
      "discovery.type" = "single-node";
      "action.auto_create_index" = false;
      "network.host" = "127.0.0.1";
      "http.port" = 9200;
    };
    extraJavaOptions = [
      "-Xms1g"
      "-Xmx1g"
    ];
  };

  services.graylog = {
    enable = true;
    isMaster = true;
    passwordSecret = "\${GRAYLOG_PASSWORD_SECRET}";
    rootUsername = "admin";
    rootPasswordSha2 = "\${GRAYLOG_ROOT_PASSWORD_SHA2}";
    mongodbUri = "mongodb://127.0.0.1:27017/graylog";
    elasticsearchHosts = [ "http://127.0.0.1:9200" ];
    extraConfig = ''
      http_bind_address = 0.0.0.0:9000
      http_publish_uri = http://logger:9000/
      http_external_uri = https://logs.basn.se/
      allow_leading_wildcard_searches = true
    '';
  };

  systemd.services.graylog.serviceConfig.EnvironmentFile = lib.mkAfter [
    config.sops.templates."graylog-env".path
  ];

  services.rsyslogd = {
    enable = true;
    extraConfig = ''
      module(load="imudp")
      module(load="imtcp")
      input(type="imudp" port="1514")
      input(type="imtcp" port="1514")
    '';
  };
}
