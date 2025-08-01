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
        };
        signal = {
          enable = true;
          enableNginx = true;
        };
      };
    };
  };
  environment = {
    systemPackages = [ pkgs.netbird-ui ];
  };
}
