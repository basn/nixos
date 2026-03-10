{ pkgs, ... }:
{
  services = {
    postgresql = {
      enable = true;
      #ensureDatabases = [ "teslamate" ];
      package = pkgs.postgresql_17;
      enableTCPIP = true;
      authentication = pkgs.lib.mkOverride 10 ''
        #type database  DBuser  auth-method
        local all       all     trust
        local teslamate teslamate  trust
      '';
    };
  };
}
