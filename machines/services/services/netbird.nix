{ pkgs, ... }:
{
  services = {
    netbird = {
      server = {
        enable = true;
        domain = "netbird.basn.se";
        nginx = true;
      };
    };
  };
  environment = {
    systemPackages = [ pkgs.netbird-ui ];
  };
}
