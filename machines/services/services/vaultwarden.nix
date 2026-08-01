{ unstableSmall, ... }:
{
  services = {
    vaultwarden = {
      enable = true;
      package = unstableSmall.vaultwarden;
      dbBackend = "sqlite";
      backupDir = "/vaultwarden";
      config = {
        ROCKET_ADDRESS = "0.0.0.0";
        ROCKET_PORT = 8222;
        DOMAIN = "https://vaultwarden.basn.se";
        SIGNUPS_ALLOWED = false;
      };
    };
  };
}
