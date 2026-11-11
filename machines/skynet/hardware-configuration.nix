# Fresh VMware VM using the nixos-sov boot and ZFS dataset layout.
{ lib, ... }:
{
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "vmw_pvscsi"
    "floppy"
    "sd_mod"
    "sr_mod"
  ];

  fileSystems."/" = {
    device = "osdisk/root";
    fsType = "zfs";
  };
  fileSystems."/nix" = {
    device = "osdisk/nix";
    fsType = "zfs";
  };
  fileSystems."/var" = {
    device = "osdisk/var";
    fsType = "zfs";
  };
  fileSystems."/home" = {
    device = "osdisk/home";
    fsType = "zfs";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/SKYNET-EFI";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [ ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
