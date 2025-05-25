{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../common/common.nix
      ./sops.nix
      ./services/podman.nix
      ./services/blocky.nix
      ./services/nginx.nix
      ./services/kuma.nix
      ./services/pykms.nix
      ./services/vaultwarden.nix
      ./services/unifi.nix
      ./services/ac.nix
    ];
  boot = {
    zfs = {
      extraPools = [ "tank" ];
      devNodes = "/dev/disk/by-path";
    };
    loader.grub = {
      enable = true;
      zfsSupport = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      mirroredBoots = [
        { devices = [ "nodev"]; path = "/boot"; }
      ];
    };
    kernel = {
       sysctl = {
         "net.core.rmem_max" = 2500000;
         "net.core.wmem_max" = 2500000;
	 "net.core.wmem_default" = 2000000;
       };
    };
  };
  networking = {
    interfaces = { 
      eth0.ipv4.addresses = [ 
        {
          address = "10.1.1.8";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = "10.1.1.1";
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
    hostId = "629e8a9b";
    enableIPv6  = false;
    hostName = "services";
    timeServers = [ "ntp1.sp.se" ];
  };
  environment.systemPackages = with pkgs; [
    open-vm-tools-headless
    podman
    blocky
    nginx
  ];

  services = {
    openssh = {
      enable = true;
    };
    zfs = {
      autoScrub = {
        enable = true;
      };
    };
  };
  virtualisation.vmware.guest.enable = true;
  networking = {
    firewall = {
      allowedTCPPorts = [ 22 80 443 3000 3306 8080 8686 8772 9080 9443 4000 9090 8222 ];
      allowedTCPPortRanges = [
        { from = 8081; to = 8085; }
	{ from = 9600; to = 9603; }
      ];
      allowedUDPPorts = [ 53 69 3478 10001 ];
      allowedUDPPortRanges = [ 
        { from = 9600; to = 9603; }
      ];
    };
  };
  system = {
    stateVersion = "23.11";
    autoUpgrade = {
      flake = "github:basn/nixos";
      enable = true;
    };
  };
}

