{ config, ... }:
{
  systemd.services.acservermanager = {
    description = "server manager for assettocorsa";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "basn";
      ExecStart = "${config.users.users.basn.home}/ac_servermanager/assetto-multiserver-manager";
      WorkingDirectory="${config.users.users.basn.home}/ac_servermanager/";
    };
  };
}
