{config, lib, pkgs, ...}:
{
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
      "cygate.basn.se" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
           proxyPass =  "http://127.0.0.1:9090";
         };
      };
    };
  };
}
