{ pkgs, ... }:
{
  services = {
    netbird = {
      server = {
        enable = true;
        domain = "netbird.basn.se";
        enableNginx = true;
        dashboard = {
          enable = true;
          enableNginx = true;
          settings = {
            AUTH_AUTHORITY = false;
          };
        };
        signal = {
          enable = true;
          enableNginx = true;
        };
      };
    };
  };
  environment = {
    systemPackages = with pkgs; [
      netbird-ui
      netbird-dashboard
      netbird
    ];
  };
}
