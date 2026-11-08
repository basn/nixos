{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
    virtualHosts = {
      "tube.basn.se" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:18082";
          proxyWebsockets = true;
          recommendedProxySettings = false;
          extraConfig = ''
            allow 10.1.1.8/32;
            deny all;
            client_max_body_size 2g;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $http_x_real_ip;
            proxy_set_header X-Forwarded-For $http_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
            proxy_set_header X-Forwarded-Host $http_x_forwarded_host;
            proxy_set_header Authorization $http_authorization;
            proxy_read_timeout 300;
            proxy_send_timeout 300;
            proxy_buffering off;
          '';
        };
      };
      "rt.basn.se" = {
        locations."/" = {
          proxyPass = "http://192.168.15.1:8080";
          extraConfig = "allow 192.168.0.0/16;" + "allow 10.1.1.8/32;" + "allow 127.0.0.1/32;" + "deny all;";
        };
      };
      "pods.basn.se" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:8040";
          proxyWebsockets = true;
          recommendedProxySettings = false;
          extraConfig = ''
            allow 10.1.1.8/32;
            deny all;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $http_x_real_ip;
            proxy_set_header X-Forwarded-For $http_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
            proxy_set_header X-Forwarded-Host $http_x_forwarded_host;
          '';
        };
      };
      "muxarr.basn.se" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:8183";
          proxyWebsockets = true;
          extraConfig = ''
            allow 10.1.1.8/32;
            deny all;
          '';
        };
      };
    };
  };
}
