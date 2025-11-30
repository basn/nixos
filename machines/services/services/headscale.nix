{ config, pkgs, ... }:
let
  name = "headscale";
  basedomain = "basn.se";
in
{
  environment = {
    systemPackages = [ pkgs.headscale ];
  };
  services = {
    headscale = {
      enable = true;
      address = "0.0.0.0";
      port = 8181;
      settings = {
        server_url = "https://${name}.${basedomain}";
        dns = {
          base_domain = "w.${basedomain}";
          nameservers = {
            global = [
              "1.1.1.1"
              "8.8.8.8"
            ];
          };
        };
      };
    };
    nginx = {
      virtualHosts = {
        "${name}.${basedomain}" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://localhost:${toString config.services.headscale.port}";
            proxyWebsockets = true;
          };
        };
      };
    };
  };
}
