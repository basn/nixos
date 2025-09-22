{ config, ... }:
{
  services = {
    samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          workgroup = "workgroup";
          "server string" = "NixOS NAS";
          "netbios name" = config.networking.hostName;
          security = "user";
          "min protocol" = "SMB2";
          "client min protocol" = "SMB2";
        };
        storage = {
          path = "/storage";
          browseable = true;
          writable = true;
          "guest ok" = false;
          "valid users" = "basn";
          "create mask" = "0644";
          "directory mask" = "0755";
          "force user" = "basn";
          "force group" = "users";          
        };
      };
    };
  };
}
