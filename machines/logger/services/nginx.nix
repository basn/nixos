{ pkgs, ... }:
{
  systemd.services.generate-logger-selfsigned-cert = {
    description = "Generate self-signed TLS certificate for logger nginx";
    wantedBy = [ "multi-user.target" ];
    before = [ "nginx.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      install -d -m 0750 /var/lib/logger-certs
      if [ ! -s /var/lib/logger-certs/logger.key ] || [ ! -s /var/lib/logger-certs/logger.crt ]; then
        ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
          -keyout /var/lib/logger-certs/logger.key \
          -out /var/lib/logger-certs/logger.crt \
          -subj "/CN=logs.basn.se"
        chmod 0600 /var/lib/logger-certs/logger.key
        chmod 0644 /var/lib/logger-certs/logger.crt
      fi
    '';
  };

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
    virtualHosts."logs.basn.se" = {
      addSSL = true;
      sslCertificate = "/var/lib/logger-certs/logger.crt";
      sslCertificateKey = "/var/lib/logger-certs/logger.key";
      locations."/" = {
        proxyPass = "http://127.0.0.1:9000";
        proxyWebsockets = true;
      };
    };
  };
}
