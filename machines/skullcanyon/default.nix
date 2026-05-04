{ lib, pkgs, config, ... }:
let
  zfsCompatibleKernelPackages = lib.filterAttrs (
    name: kernelPackages:
    (builtins.match "linux_[0-9]+_[0-9]+" name) != null
    && (builtins.tryEval kernelPackages).success
    && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
  ) pkgs.linuxKernel.packages;
  latestKernelPackage = lib.last (
    lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
      builtins.attrValues zfsCompatibleKernelPackages
    )
  );
in
{
  boot = {
    kernelPackages = latestKernelPackage;
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
  networking = {
    defaultGateway = "192.168.195.1";
    nameservers = [ "192.168.195.1" ];
    hostId = "9757610d";
    enableIPv6 = false;
    hostName = "skullcanyon";
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
      uplink = "eno1";
      nativeBridges = {
        br0 = {
          ipv4Addresses = [
            {
              address = "192.168.195.15";
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
    "/home" = {
      device = "osdisk/home";
      fsType = "zfs";
    };
    "/boot" = {
      device = "/dev/disk/by-partuuid/58372a76-6fb3-41aa-86bb-d66b3806d45f";
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
  programs.nh.clean = {
    enable = true;
    dates = "Sun *-*-* 05:30:00";
    extraArgs = lib.mkForce "--keep-since 14d --keep 10";
  };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system = {
    stateVersion = "24.05";
    autoUpgrade = {
      flake = "github:basn/nixos";
      enable = true;
    };
  };
}
