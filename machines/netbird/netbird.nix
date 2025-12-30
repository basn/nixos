{ config, unstablePkgs, ... }:
let
  ClientID = "YevEd2xwJurQd4uDuZIIBrYI1pyXuJ8qNltPzRl5";
in
{
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "basn@lan2k.org";
      webroot = "/var/lib/acme/acme-challenge";
    };
  };
  services = {
    netbird = {
      server = {
        enable = true;
        domain = "netbird.basn.se";
        enableNginx = true;
        dashboard = {
          enable = true;
          enableNginx = true;
          package = unstablePkgs.netbird-dashboard;
          settings = {
            USE_AUTH0 = false;
            AUTH_AUDIENCE = ClientID;
            AUTH_CLIENT_ID = ClientID;
            AUTH_AUTHORITY = "https://auth.basn.se/application/o/netbird/";
            AUTH_SUPPORTED_SCOPES = "openid profile email offline_access api";
            AUTH_REDIRECT_URI = "/peers";
            AUTH_SILENT_REDIRECT_URI = "/add-peers";
          };
        };
        management = {
          enable = true;
          port = 8011;
          logLevel = "ERROR";
          turnPort = 3478;
          turnDomain = config.services.netbird.server.domain;
          oidcConfigEndpoint = "https://auth.basn.se/application/o/netbird/.well-known/openid-configuration";
          metricsPort = 9092;
          dnsDomain = "netbird.basn.se";
          enableNginx = true;
          package = unstablePkgs.netbird-management;
          settings = {
            HttpConfig = {
              AuthIssuer = "https://auth.basn.se/application/o/netbird/";
              AuthAudience = ClientID;
              AuthKeysLocation = "https://auth.basn.se/application/o/netbird/jwks/";
              AuthUserIDClaim = "";
              IdpSignKeyRefreshEnabled = false;
            };
            IdpManagerConfig = {
              ManagerType = "authentik";
              ClientConfig = {
                Issuer = "https://auth.basn.se/application/o/netbird/";
                TokenEndpoint = "https://auth.basn.se/application/o/token/";
                ClientID = ClientID;
                ClientSecret = "";
                GrantType = "client_credentials";
              };
              ExtraConfig = {
                Password =  { _secret = "/var/run/secrets/idp"; };
                Username = "netbird";
              };
            };
            DeviceAuthorizationFlow = {
              Provider = "hosted";
              ProviderConfig = {
                Audience = ClientID;
                AuthorizationEndpoint = "";
                Domain = "";
                ClientID = ClientID;
                ClientSecret = "";
                TokenEndpoint = "https://auth.basn.se/application/o/token/";
                DeviceAuthEndpoint = "https://auth.basn.se/application/o/device/";
                Scope = "openid";
                UseIDToken = false;
                RedirectURLs = null;
              };
            };

            PKCEAuthorizationFlow = {
              ProviderConfig = {
                Audience = ClientID;
                ClientID = ClientID;
                ClientSecret = "";
                Domain = "";
                AuthorizationEndpoint = "https://auth.basn.se/application/o/authorize/";
                TokenEndpoint = "https://auth.basn.se/application/o/token/";
                Scope = "openid profile email offline_access api";
                RedirectURLs = null;
                UseIDToken = false;
                DisablePromptLogin = true;
                LoginFlag = 0;
              };
            };
            TURNConfig = {
              Secret = { _secret = "/var/run/secrets/coturn"; };
            };
            DataStoreEncryptionKey = {
              _secret = config.sops.secrets.datastore.path;
            };
          };
        };
        coturn = {
          enable = true;
          domain = config.services.netbird.server.domain;
          useAcmeCertificates = false;
          passwordFile = config.sops.secrets.coturn.path;
        };
        signal = {
          port = 8012;
          enable = true;
          package = unstablePkgs.netbird-signal;
        };
      };
    };
    nginx = {
      commonHttpConfig = ''
        add_header Access-Control-Allow-Origin "*.basn.se" always;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
      '';
      virtualHosts."netbird.basn.se" = {
        enableACME = true;
        forceSSL = true;
      };
    };
  };
}
