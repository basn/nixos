{ lib, ... }:
{
  imports = [
    ../../common/common.nix
    ./netbird.nix
    ./sops.nix
  ];
  boot = {
    zfs = {
      extraPools = [ "osdisk" ];
      devNodes = "/dev/disk/by-path";
    };
    loader = {
      systemd-boot = {
        enable = true;
      };
      efi = {
        canTouchEfiVariables = true;
      };
    };
    initrd = {
      availableKernelModules = [
        "ata_piix"
        "vmw_pvscsi"
        "floppy"
        "sd_mod"
        "sr_mod"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ ];
    extraModulePackages = [ ];
  };
  networking = {
    interfaces = {
      eth0.ipv4.addresses = [
        {
          address = "10.140.12.20";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = "10.140.12.1";
    nameservers = [ "8.8.8.8" ];
    hostId = "8012ebed";
    enableIPv6 = false;
    hostName = "netbird";
    timeServers = [ "ntp1.sp.se" ];
    useDHCP = lib.mkDefault false;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
        443
      ];
      checkReversePath = "loose";
    };
  };
  fileSystems = {
    "/" = {
      device = "osdisk/root";
      fsType = "zfs";
    };
    "/nix" = {
      device = "osdisk/nix";
      fsType = "zfs";
    };
    "/var" = {
      device = "osdisk/var";
      fsType = "zfs";
    };
    "/home" = {
      device = "osdisk/home";
      fsType = "zfs";
    };
    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
  };
  services = {
    openssh.enable = true;
    zfs.autoScrub.enable = true;
  };
  virtualisation.vmware.guest.enable = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system = {
    stateVersion = "24.05";
    autoUpgrade = {
      flake = "github:basn/nixos";
      enable = true;
    };
  };
}
