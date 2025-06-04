{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./services/kuma.nix
      ./services/nginx.nix
      ../common/common.nix
    ];

  boot = {
    zfs = {
      extraPools = [ "osdisk" ];
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
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
    hostId = "e5dafd0b";
    enableIPv6  = false;
    hostName = "nixos-sov2";
    timeServers = [ "ntp1.sp.se" ];
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ];
    };
  };
  environment.systemPackages = with pkgs; [
  ];

  services = {
    openssh.enable = true;
    zfs.autoScrub.enable = true;
  };
  virtualisation.vmware.guest.enable = true;
  system = {
    stateVersion = "25.05";
    autoUpgrade = {
      flake = "github:basn/nixos";
      enable = true;
    };
  };
}
