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
      "rt.basn.se" = {
        locations."/" = {
          proxyPass = "http://192.168.15.1:8080";
          extraConfig = "allow 192.168.0.0/16;" + "allow 10.1.1.8/32;" + "allow 127.0.0.1/32;" + "deny all;";
        };
      };
    };
  };
}
