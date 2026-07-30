{
  lib,
  pkgs,
  ...
}:
{
  imports = [
  ];

  basn.boot.useLatestZfsCompatibleKernel = true;

  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs = {
      package = pkgs.zfs_2_4;
      extraPools = [ "osdisk" ];
      devNodes = "/dev/disk/by-path";
      forceImportRoot = false;
    };
    loader = {
      systemd-boot = {
        enable = true;
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "sdhci_pci"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
  };

  networking = {
    defaultGateway = "192.168.195.1";
    nameservers = [ "192.168.195.1" ];
    hostId = "dc4e08d2";
    enableIPv6 = false;
    hostName = "lenovo";
    timeServers = [ "ntp1.sp.se" ];
    useDHCP = lib.mkDefault false;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
        443
      ];
    };
  };

  basn = {
    virtualisation = {
      libvirt = {
        enable = true;
        qemu.runAsRoot = false;
      };
    };
    network.bridgeLayout = {
      enable = true;
      uplink = "enp0s31f6";
      nativeBridges = {
        br0 = {
          ipv4Addresses = [
            {
              address = "192.168.195.16";
              prefixLength = 24;
            }
          ];
        };
      };
      vlanBridges = {
        br7 = {
          vlanId = 7;
        };
      };
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
    "/var/lib/libvirt/images" = {
      device = "osdisk/vms";
      fsType = "zfs";
    };
    "/var/lib/libvirt/images/hermes" = {
      device = "osdisk/vms/hermes";
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

  services.sanoid = {
    enable = true;
    templates.hermes = {
      hourly = 24;
      daily = 14;
      monthly = 3;
      autoprune = true;
      autosnap = true;
    };
    datasets."osdisk/vms/hermes".useTemplate = [ "hermes" ];
  };

  programs.nh.clean = {
    enable = true;
    dates = "Sun *-*-* 05:30:00";
    extraArgs = lib.mkForce "--keep-since 14d --keep 10";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  system.stateVersion = "24.05";
}
