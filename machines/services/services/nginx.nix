{ pkgs, ...}:
let
  authentikConfig = {
    extraConfig = ''
    proxy_buffers 8 16k;
    proxy_buffer_size 32k;
    location /outpost.goauthentik.io {
      proxy_pass              http://localhost:9000/outpost.goauthentik.io;
      proxy_set_header        Host $host;
      proxy_set_header        X-Original-URL $scheme://$http_host$request_uri;
      add_header              Set-Cookie $auth_cookie;
      auth_request_set        $auth_cookie $upstream_http_set_cookie;
      proxy_pass_request_body off;
      proxy_set_header        Content-Length "";
    }
    location @goauthentik_proxy_signin {
      internal;
      add_header Set-Cookie $auth_cookie;
      return 302 /outpost.goauthentik.io/start?rd=$scheme://$http_host$request_uri;
    }
    '';
  };
  authentikAuth = {
    extraConfig = ''
      auth_request /outpost.goauthentik.io/auth/nginx;
      error_page 401 = @goauthentik_proxy_signin;
      auth_request_set $auth_cookie $upstream_http_set_cookie;
      add_header Set-Cookie $auth_cookie;
      auth_request_set $authentik_username $upstream_http_x_authentik_username;
      auth_request_set $authentik_groups $upstream_http_x_authentik_groups;
      auth_request_set $authentik_entitlements $upstream_http_x_authentik_entitlements;
      auth_request_set $authentik_email $upstream_http_x_authentik_email;
      auth_request_set $authentik_name $upstream_http_x_authentik_name;
      auth_request_set $authentik_uid $upstream_http_x_authentik_uid;
      proxy_set_header X-authentik-username $authentik_username;
      proxy_set_header X-authentik-groups $authentik_groups;
      proxy_set_header X-authentik-entitlements $authentik_entitlements;
      proxy_set_header X-authentik-email $authentik_email;
      proxy_set_header X-authentik-name $authentik_name;
      proxy_set_header X-authentik-uid $authentik_uid;
    '';
  };
in
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
      "auth.basn.se" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "https://localhost:9443";
          proxyWebsockets = true;
        };
      };
      "rt.basn.se" = {
        enableACME = true;
        forceSSL = true;
	locations."/" = {
           proxyPass =  "http://192.168.180.10:80";
           extraConfig =
             "allow 192.168.0.0/16;"+
             "allow 10.1.1.0/24;"+
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
      "prowlarr.basn.se" = authentikConfig // {
        enableACME = true;
        forceSSL = true;
        locations."/" = authentikAuth // {
          proxyPass =  "http://192.168.180.10:9696";
        };
      };
      "sonarr.basn.se" = authentikConfig // {
        enableACME = true;
        forceSSL = true;
        locations."/" = authentikAuth // {
          proxyPass = "http://192.168.180.10:8989";
        };
      };
      "radarr.basn.se" = authentikConfig // {
        enableACME = true;
        forceSSL = true;
        locations."/" = authentikAuth // {
          proxyPass =  "http://192.168.180.10:7878";
        };
      };
      "valetudo.basn.se" = {
         enableACME = true;
         forceSSL = true;
         locations."/" = {
           proxyPass =  "http://10.0.1.11";
           extraConfig =
             "allow 192.168.195.0/24;"+
             "allow 192.168.196.0/24;"+
             "allow 10.1.1.0/24;"+
             "allow 127.0.0.1/32;"+
             "deny all;"
             ;
         };
      };
      "tesla.basn.se" = authentikConfig // {
         enableACME = true;
         forceSSL = true;
         locations."/" = authentikConfig // {
           proxyPass =  "http://127.0.0.1:4000";
	   recommendedProxySettings = false;
           proxyWebsockets = true; 
         };
      };
      "grafana.basn.se" = {
         enableACME = true;
         forceSSL = true;
         locations."/" = authentikAuth // {
           proxyPass =  "http://127.0.0.1:3000";
           recommendedProxySettings = false;
           proxyWebsockets = true;
         };
      };
      "uptime.basn.se" = {
         enableACME = true;
         forceSSL = true;
         locations."/" = {
           proxyPass =  "http://127.0.0.1:9090";
           recommendedProxySettings = true;
           proxyWebsockets = true;
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
