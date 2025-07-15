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
      server_url = "${name}.${basedomain}";
      dns = {
        basedomain = "${basedomain}";
      };
      logtail = {
        enabled = true;
      };
    };
    nginx = {
      virtualHosts = {
        ${name}.${basedomain} = {
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
