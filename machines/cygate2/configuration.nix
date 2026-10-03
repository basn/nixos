{
  config,
  lib,
  ...
}:

{
  imports = [
    ../../modules/dayzweb-split.nix
    ./hardware-configuration.nix
    ./services/kuma.nix
    ./services/nginx.nix
    ./services/syncoid.nix
  ];

  users.users.dayzweb = {
    isSystemUser = true;
    group = "dayzweb";
  };
  users.groups.dayzweb = { };

  systemd.tmpfiles.rules = [
    "d /srv/dayzweb 0755 root root -"
    "d /srv/dayzweb/releases 0755 root root -"
  ];

  services.dayzwebSplit = {
    sourcePath = "/srv/dayzweb/current";
    user = "dayzweb";
    netbirdUnits = [ "netbird.service" ];
    worker = {
      enable = true;
      ingestUrl = "http://services.netbird.basn.se:18111";
      serverId = "1ed9f69d-4ee3-6dac-b18b-ea5e938a80e2";
      detailConcurrency = 8;
    };
  };

  boot = {
    zfs = {
      extraPools = [ "osdisk" ];
      devNodes = "/dev/disk/by-path";
      forceImportRoot = false;
    };
    loader.grub = {
      enable = true;
      zfsSupport = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      mirroredBoots = [
        {
          devices = [ "nodev" ];
          path = "/boot";
        }
      ];
    };
  };
  networking = {
    interfaces = {
      eth0.ipv4.addresses = [
        {
          address = "10.136.37.5";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = "10.136.37.1";
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
    hostId = "e5dafd0c";
    enableIPv6 = false;
    hostName = "nixos-sov2";
    timeServers = [ "ntp1.sp.se" ];
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
        443
      ];
    };
  };
  virtualisation.vmware.guest.enable = true;
  system.stateVersion = "25.05";
}
