{config, ...}: {
  services = {
    netbird = {
      server = {
        enable = true;
        domain = "netbird.basn.se";
        dashboard = {
          enable = true;
          settings = {
            AUTH_AUTHORITY = "https://auth.basn.se/application/o/netbird/";
            AUTH_CLIENT_ID = "netbird";
            AUTH_AUDIENCE = "netbird";
            USE_AUTH0 = false;
            MGMT_IDP = "authentik";
            AUTH_SUPPORTED_SCOPES = "openid profile email";
            IDP_MGMT_CLIENT_ID = "YevEd2xwJurQd4uDuZIIBrYI1pyXuJ8qNltPzRl5";
            IDP_MGMT_EXTRA_USERNAME = "netbird";
            IDP_MGMT_EXTRA_PASSWORD = "EkZzZm8GAhAf8rk3kbnApNTxXfrTaxSmmGctNIV4e6OK6xxpPUt3BMT591kk";
            AUTH_PKCE_DISABLE_PROMPT_LOGIN = true;
          };
        };
        management = {
          enable = true;
          port = 8011;
          logLevel = "ERROR";
          oidcConfigEndpoint = "https://auth.basn.se/application/o/netbird/.well-known/openid-configuration";
          turnPort = 3478;
          turnDomain = config.services.netbird.domain;
          metricsPort = 9092;
          dnsDomain = "netbird.basn.se";
          enableNginx = false;
          settings = {
            DataStoreEncryptionKey = {
              _secret = "/var/lib/netbird-mgmt/enc.key";
            };
          };
        };
        coturn = {
          enable = true;
          domain = config.services.netbird.domain;
          user = "netbird";
          useAcmeCertificates = false;
          passwordFile = /netbird_coturn.secret;
        };
      };
    };
  };
}
