{ inputs, pkgs, ... }:
{
  imports = [ 
    inputs.sops_nix.nixosModules.sops
    ../../common/common.nix
    ./samba.nix
  ];
  boot = {
    kernelModules = [ "kvm-intel" ];
    supportedFilesystems = [ "zfs" ];
    initrd = {
      kernelModules = [ ];
      availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "sdhci_pci" ];
      };
    zfs = {
      devNodes = "/dev/disk/by-id";
    };
    loader = {
      grub = {
        enable = true;
        zfsSupport = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        mirroredBoots = [
          { devices = [ "nodev" ]; path = "/boot1"; }
          { devices = [ "nodev" ]; path = "/boot2"; }
          { devices = [ "nodev" ]; path = "/boot3"; }
        ];
      };
    };
  };
  fileSystems = {
    "/" ={
      device = "storage/root";
      fsType = "zfs";
    };
    "/nix" = {
      device = "storage/nix";
      fsType = "zfs";
    };
    "/var" = {
      device = "storage/var";
      fsType = "zfs";
    };
    "/home" = {
      device = "storage/home";
      fsType = "zfs";
      neededForBoot = true;
    };
    "/storage" = {
      device = "storage/nas";
      fsType = "zfs";
    };
    "/berget" = {
      device = "storage/berget";
      fsType = "zfs";
    };
    "/boot1" = {
      device = "/dev/disk/by-label/boot1";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };
    "/boot2" = {
      device = "/dev/disk/by-label/boot2";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };
    "/boot3" = {
      device = "/dev/disk/by-label/boot3";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ]; 
    };
  };
  networking = {
    interfaces = {
       enp2s0 = {
        useDHCP = true;
       };
    };
    nameservers = [ "10.1.1.8" ];
    enableIPv6  = false;
    timeServers = [ "ntp1.sp.se" ];
    hostName = "vault"; 
    hostId = "8ede279f";
    firewall = { 
      enable = true;
      allowedTCPPorts = [ 22 80 ];
    };
  };
  environment = {
    systemPackages = with pkgs; [
      rclone
    ];
  };
  services = {
    openssh = {
      enable = true;
    };
    zfs = {
      autoScrub = {
        enable = true;
      };
      trim = {
        enable = true;
      };
    };
    smartd = {
      enable = true;
      autodetect = true;
    };
  };
  powerManagement = {
    powertop = {
      enable = true;
    };
  };
  hardware = {
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vpl-gpu-rt
	intel-ocl
        libva-vdpau-driver
        intel-compute-runtime
      ];
    };
    cpu = {
      intel = {
        updateMicrocode = true;
      };
    };
  };
  system = {
    stateVersion = "24.05";
    autoUpgrade = {
      flake = "github:basn/nixos";
      enable = true;
    };
  };
}
