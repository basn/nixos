{ lib, ... }:
{
  imports = [
    ./nvidia.nix
    ./ollama.nix
  ];
  boot = {
    initrd.availableKernelModules = [
      "ata_piix"
      "vmw_pvscsi"
      "floppy"
      "sd_mod"
      "sr_mod"
    ];
    zfs = {
      extraPools = [
        "osdisk"
      ];
      devNodes = "/dev/disk/by-path";
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
  networking = {
    interfaces = {
      eth0.ipv4.addresses = [
        {
          address = "10.254.1.2";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = "10.254.1.1";
    nameservers = [ "8.8.8.8" ];
    hostId = "5b8ea90e";
    enableIPv6 = false;
    hostName = "skynet";
    timeServers = [ "ntp1.sp.se" ];
    useDHCP = false;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
        443
      ];
    };
  };
  services = {
    openssh.enable = true;
    zfs.autoScrub.enable = true;
  };
  virtualisation.vmware.guest.enable = true;
  system = {
    stateVersion = "25.11";
    autoUpgrade = {
      flake = "github:basn/nixos";
      enable = true;
    };
  };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
