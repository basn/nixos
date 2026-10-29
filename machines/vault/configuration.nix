{
  inputs,
  pkgs,
  config,
  ...
}:
{
  imports = [
    inputs.sops_nix.nixosModules.sops
    ./services/samba.nix
    ./services/rsync.nix
    ./services/znapzend.nix
    ./services/backupuser.nix
    ./services/network-link-recovery.nix
    ../../modules/nut-client.nix
    ./sops.nix
  ];

  basn.boot.useLatestZfsCompatibleKernel = true;
  boot = {
    kernelModules = [ "kvm-intel" ];
    kernelParams = [ "pcie_aspm=off" ];
    supportedFilesystems = [ "zfs" ];
    initrd = {
      kernelModules = [ ];
      availableKernelModules = [
        "xhci_pci"
        "nvme"
        "usb_storage"
        "sd_mod"
        "sdhci_pci"
      ];
    };
    zfs = {
      package = pkgs.zfs_2_4;
      devNodes = "/dev/disk/by-id";
      forceImportRoot = false;
    };
    loader = {
      grub = {
        enable = true;
        zfsSupport = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        mirroredBoots = [
          {
            devices = [ "nodev" ];
            path = "/boot1";
          }
          {
            devices = [ "nodev" ];
            path = "/boot2";
          }
          {
            devices = [ "nodev" ];
            path = "/boot3";
          }
        ];
      };
    };
  };
  fileSystems = {
    "/" = {
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
    "/storage/home-assistant-backups" = {
      device = "storage/home-assistant-backups";
      fsType = "zfs";
    };
    "/berget" = {
      device = "storage/berget";
      fsType = "zfs";
    };
    "/boot1" = {
      device = "/dev/disk/by-label/boot1";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
    "/boot2" = {
      device = "/dev/disk/by-label/boot2";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
    "/boot3" = {
      device = "/dev/disk/by-label/boot3";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
  };
  # Persistent swap on a ZFS zvol; provisioned as storage/swap.
  swapDevices = [ { device = "/dev/zvol/storage/swap"; } ];
  networking = {
    interfaces = {
      enp1s0 = {
        useDHCP = true;
      };
    };
    nameservers = [ "10.1.1.8" ];
    enableIPv6 = false;
    timeServers = [ "ntp1.sp.se" ];
    hostName = "vault";
    hostId = "8ede279f";
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
      ];
    };
  };
  environment = {
    systemPackages = with pkgs; [ rclone ];
  };
  services = {
    # I226-V runtime-PM mitigation; evidence and review conditions: README.md.
    # Match only enp1s0's PCI device, not Vault's other Intel NIC.
    udev.extraRules = ''
      ACTION=="add|change", SUBSYSTEM=="pci", KERNEL=="0000:01:00.0", ATTR{vendor}=="0x8086", ATTR{device}=="0x125c", TEST=="power/control", ATTR{power/control}="on"
    '';
    zfs = {
      trim = {
        enable = true;
      };
    };
  };
  basn.nutClient = {
    enable = true;
    passwordFile = config.sops.secrets.nut-upsmon.path;
  };
  powerManagement = {
    powertop = {
      enable = true;
      # Restore only the I226-V policy after auto-tuning; review/removal: README.md.
      postStart = ''
        device=/sys/bus/pci/devices/0000:01:00.0
        if [ ! -r "$device/vendor" ] || [ ! -r "$device/device" ]; then
          echo "powertop: cannot identify expected I226-V at $device" >&2
          exit 1
        fi
        if [ "$(cat "$device/vendor")" != 0x8086 ] || [ "$(cat "$device/device")" != 0x125c ]; then
          echo "powertop: PCI identity mismatch at $device; refusing runtime-PM override" >&2
          exit 1
        fi
        if [ ! -e "$device/power/control" ]; then
          echo "powertop: missing $device/power/control; cannot restore I226-V runtime-PM policy" >&2
          exit 1
        fi
        if ! printf 'on\n' > "$device/power/control"; then
          echo "powertop: failed to restore $device/power/control to on" >&2
          exit 1
        fi
      '';
    };
  };
  hardware = {
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vpl-gpu-rt
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
  system.stateVersion = "24.05";
}
