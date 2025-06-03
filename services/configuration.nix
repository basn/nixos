{ pkgs, ... }:

{
  imports =
    [ 
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
      ./services/teslamate.nix
    ];
  boot = {
    zfs = {
      extraPools = [ "tank" ];
      devNodes = "/dev/disk/by-path";
    };
    loader = {
      grub = {
        enable = true;
        zfsSupport = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        mirroredBoots = [
          { devices = [ "nodev"]; path = "/boot"; }
        ];
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
  virtualisation = {
    vmware = {
      guest = {
        enable = true;
        package = pkgs.open-vm-tools-headless;
      };
    };
  };
  networking = {
    firewall = {
      allowedTCPPorts = [ 22 80 443 ];
      allowedUDPPorts = [ 53 ];
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
