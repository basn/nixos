{ ... }:
{
  boot = {
    kernel = {
       sysctl = {
         "net.core.rmem_max" = 2500000;
         "net.core.wmem_max" = 2500000;
         "net.core.wmem_default" = 2000000;
       };
    };
  };
  networking = {
    firewall = {
      allowedTCPPortRanges = [
        { from = 8081; to = 8085; }
        { from = 9600; to = 9603; }
      ];
      allowedUDPPortRanges = [
        { from = 9600; to = 9603; }
      ];
    };
  };
  systemd = {
    services = {
      acservermanager = {
        description = "server manager for assettocorsa";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          User = "basn";
          ExecStart = "${config.users.users.basn.home}/ac_servermanager/assetto-multiserver-manager";
          WorkingDirectory="${config.users.users.basn.home}/ac_servermanager/";
        };
      };
    };
  };
}
