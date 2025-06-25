{ config, lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  boot = {
    initrd = {
      availableKernelModules = [ "vmd" "xhci_pci" "mpt3sas" "ahci" "usb_storage" "sd_mod" ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    supportedFilesystems = [ "zfs" ];
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
          { devices = [ "nodev"]; path = "/boot1"; }
          { devices = [ "nodev"]; path = "/boot2"; }
        ];
      };
    };
  };
  fileSystems = {
    "/" ={
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
      neededForBoot = true;
    };
    "/data/files" = {
      device = "data/files";
      fsType = "zfs";
      encrypted.keyFile = "/root/zfs-data.key";
    };
    "/data2/files" = {
      device = "data2/files";
      fsType = "zfs";
      encrypted.keyFile = "/root/zfs-data2.key";
    };
    "/boot1" = {
      device = "/dev/disk/by-uuid/7821-EDA9";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };
    "/boot2" = {
      device = "/dev/disk/by-uuid/7824-6948";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };
  };
  swapDevices = [ ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
