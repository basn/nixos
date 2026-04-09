{
  lib,
  ...
}:
{
  imports = [ ];

  boot.initrd.availableKernelModules = [
    "ahci"
    "sd_mod"
    "sr_mod"
    "virtio_pci"
    "virtio_scsi"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "tank/root";
    fsType = "zfs";
  };

  fileSystems."/var/lib/opensearch" = {
    device = "tank/opensearch";
    fsType = "zfs";
  };

  fileSystems."/var/lib/mongodb" = {
    device = "tank/mongodb";
    fsType = "zfs";
  };

  fileSystems."/var/lib/graylog-server" = {
    device = "tank/graylog";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/EFI";
    fsType = "vfat";
  };

  swapDevices = [ ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
