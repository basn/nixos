{ pkgs, ...}:
{
  environment.systemPackages = with pkgs; [
    nginx
  ];
  security.acme = {
     acceptTerms = true;
     defaults = {
       email = "basn@lan2k.org";
     };
  };
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
    clientMaxBodySize = "5G";
    # Only allow PFS-enabled ciphers with AES256
    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";
    sslDhparam = "/etc/ssl/dhparam4096.pem";
    appendHttpConfig = ''
      # Add HSTS header with preloading to HTTPS requests.
      # Adding this header to HTTP requests is discouraged
      #map $scheme $hsts_header {
      #   https   "max-age=31536000; includeSubdomains; preload";
      #}  
      #add_header Strict-Transport-Security $hsts_header;

      # Enable CSP for your services.
      #add_header Content-Security-Policy "script-src 'self'; object-src 'none'; base-uri 'none';" always;

      # Minimize information leaked to other domains
      #add_header 'Referrer-Policy' 'origin-when-cross-origin';
 
      # Disable embedding as a frame
      #add_header X-Frame-Options DENY;
 
      # Prevent injection of code in other mime types (XSS Attacks)
      #add_header X-Content-Type-Options nosniff;
 
      # This might create errors
      #proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
      client_body_timeout 120s;
      client_header_timeout 120s;
      send_timeout 120s;
    '';

    virtualHosts = {
      "rt.basn.se" = {
        enableACME = true;
        forceSSL = true;
	locations."/" = {
           proxyPass =  "http://192.168.180.10:8080";
           extraConfig =
             "allow 192.168.0.0/16;"+
             "allow 127.0.0.1/32;"+
             "deny all;"
             ;
         };
      };
      "ac.basn.se" = {
        enableACME = true;
        forceSSL = true;
	locations."/" = {
          proxyPass = "http://10.1.1.8:8772";
          recommendedProxySettings = false;
          extraConfig =
	    "proxy_http_version 1.1;"+
            "proxy_set_header Upgrade $http_upgrade;"+
	    "proxy_set_header Connection $connection_upgrade;"+
            "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"+
            "proxy_set_header Host $host;"
          ;
        };
      };
      "bitwarden.basn.se" = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://10.1.1.8:8222";
      };
      "vaultwarden.basn.se" = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://10.1.1.8:8222";
      };
      "hass.basn.se" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
	  proxyPass = "http://192.168.195.35:8123";
	  recommendedProxySettings = false;
          extraConfig =
           "proxy_set_header Host $host;"+
           #"proxy_redirect http:// https://;"+
           "proxy_http_version 1.1;"+
           "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"+
           "proxy_set_header Upgrade $http_upgrade;"+
           "proxy_set_header Connection $connection_upgrade;"
           ;
        };
      };
      "prowlarr.basn.se" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass =  "http://192.168.180.10:9696";
          extraConfig =
            "allow 192.168.0.0/16;"+
            "allow 127.0.0.1/32;"+
            "deny all;"
            ;
        };
      };
      "sonarr.basn.se" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass =  "http://192.168.180.10:8989";
          extraConfig =
            "allow 192.168.0.0/16;"+
            "allow 127.0.0.1/32;"+
            "deny all;"
            ;
        };
      };
      "radarr.basn.se" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass =  "http://192.168.180.10:7878";
          extraConfig =
            "allow 192.168.0.0/16;"+
            "allow 127.0.0.1/32;"+
            "deny all;"
            ;
        };
      };
      "valetudo.basn.se" = {
         enableACME = true;
         forceSSL = true;
         locations."/" = {
           proxyPass =  "http://10.0.1.11";
           extraConfig =
             "allow 192.168.195.0/24;"+
             "allow 127.0.0.1/32;"+
             "deny all;"
             ;
         };
      };
      "tesla.basn.se" = {
         enableACME = true;
         forceSSL = true;
         locations."/" = {
           proxyPass =  "http://127.0.0.1:4000";
	   recommendedProxySettings = false;
           extraConfig =
             "proxy_http_version 1.1;"+
             "proxy_set_header Upgrade $http_upgrade;"+
             "proxy_set_header Connection $connection_upgrade;"+
             "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"+
             "proxy_set_header Host $host;"+
             "allow 192.168.195.0/24;"+
             "allow 127.0.0.1/32;"+
             "deny all;"
             ;
         };
      };
      "grafana.basn.se" = {
         enableACME = true;
         forceSSL = true;
         locations."/" = {
           proxyPass =  "http://127.0.0.1:3000";
           recommendedProxySettings = false;
           extraConfig =
             "proxy_http_version 1.1;"+
             "proxy_set_header Upgrade $http_upgrade;"+
             "proxy_set_header Connection $connection_upgrade;"+
             "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"+
             "proxy_set_header Host $host;"+
             "allow 192.168.195.0/24;"+
             "allow 127.0.0.1/32;"+
             "deny all;"
             ;
         };
      };
      "controller.basn.se" = {
         enableACME = true;
         forceSSL = true;
         locations."/" = {
           proxyPass =  "https://10.1.1.8:8443";
           recommendedProxySettings = false;
           extraConfig =
             "proxy_ssl_verify off;"+
             "proxy_ssl_session_reuse on;"+
             "proxy_buffering off;"+
             "proxy_set_header Upgrade $http_upgrade;"+
             "proxy_set_header Connection 'upgrade';"+
             "proxy_hide_header Authorization;"+
             "proxy_set_header Referer '';"+
             "proxy_set_header Origin '';"
            ;
         };
         locations."/inform" = {
           proxyPass = "https://10.1.1.8:8443";
	   recommendedProxySettings = false;
         };
      };
      "uptime.basn.se" = {
         enableACME = true;
         forceSSL = true;
         locations."/" = {
           proxyPass =  "http://127.0.0.1:9090";
           recommendedProxySettings = false;
           extraConfig =
             "proxy_http_version 1.1;"+
             "proxy_set_header Upgrade $http_upgrade;"+
             "proxy_set_header Connection $connection_upgrade;"+
             "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"+
             "proxy_set_header Host $host;"
             ;
        };
      };
      "jellyfin.basn.se" = {
         enableACME = true;
         forceSSL = true;
         locations."/" = {
           proxyPass =  "http://192.168.180.10:8096";
           recommendedProxySettings = false;
           extraConfig =
	     "proxy_set_header Host $host;"+
	     "proxy_set_header X-Real-IP $remote_addr;"+
             "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"+
	     "proxy_set_header X-Forwarded-Protocol $scheme;"+
	     "proxy_set_header X-Forwarded-Host $http_host;"+
	     "proxy_buffering off;"
             ;
	 
         };
         locations."/socket" = {
           proxyPass =  "http://192.168.180.10:8096";
           recommendedProxySettings = false;
           extraConfig =
	     "proxy_http_version 1.1;"+
	     "proxy_set_header Upgrade $http_upgrade;"+
	     "proxy_set_header Connection 'upgrade';"+
             "proxy_set_header Host $host;"+
             "proxy_set_header X-Real-IP $remote_addr;"+
             "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;"+
             "proxy_set_header X-Forwarded-Protocol $scheme;"+
             "proxy_set_header X-Forwarded-Host $http_host;"
             ;
        };
      };
      "immich.basn.se" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://192.168.180.10:2283";
          recommendedProxySettings = true;
          proxyWebsockets = true;
        };
      };
    };  
  };
}
