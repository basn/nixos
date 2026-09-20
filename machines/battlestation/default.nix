{
  config,
  pkgs,
  unstableSmall,
  ...
}:
{
  imports = [
    ./audio.nix
    ./cachyos-proton.nix
    ./desktop.nix
    ./ollama.nix
    ./opencode.nix
    ./specialisation.nix
    ./user.nix
  ];

  swapDevices = [
    {
      device = "/dev/disk/by-partuuid/28a1f5f2-a0d8-48bd-a5b9-69b0c7b545e5";
      priority = 100;
      randomEncryption.enable = true;
    }
  ];
  boot = {
    plymouth = {
      enable = true;
      theme = "nixos-bgrt";
      themePackages = [ pkgs.nixos-bgrt-plymouth ];
    };
    consoleLogLevel = 3;
    zswap = {
      enable = true;
      compressor = "zstd";
      zpool = "zsmalloc";
      maxPoolPercent = 20;
      shrinkerEnabled = true;
    };
    initrd = {
      verbose = false;
      availableKernelModules = [
        "vmd"
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      supportedFilesystems = [ "zfs" ];
    };
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 3;
        # systemd-boot has one authoritative ESP. Keep an identical copy on
        # the second member of the osdisk mirror for independent EFI booting.
        extraInstallCommands = ''
          if ${pkgs.util-linux}/bin/findmnt -rn --target /boot2 >/dev/null; then
            ${pkgs.rsync}/bin/rsync -rlt --delete /boot/ /boot2/
          fi
        '';
      };
      efi = {
        canTouchEfiVariables = true;
      };
    };
    zfs = {
      package = config.boot.kernelPackages.zfs_cachyos;
      requestEncryptionCredentials = true;
      forceImportRoot = false;
    };
    supportedFilesystems = [ "zfs" ];
    kernelModules = [
      "kvm-intel"
      "ntsync"
    ];
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-x86_64-v3;
    kernelParams = [
      "split_lock_detect=off"
      "intel_iommu=on"
      "iommu=pt"
      "quiet"
      "rd.udev.log_level=3"
      "rd.systemd.show_status=auto"
    ];
    extraModprobeConfig = "options zfs zfs_arc_max=6442450944";
  };
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };
    "/boot2" = {
      device = "/dev/disk/by-label/boot2";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
        "nofail"
        "x-systemd.device-timeout=3s"
      ];
    };
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
  };
  networking = {
    hostName = "battlestation";
    hostId = "121e3eb9";
    networkmanager.enable = true;
    enableIPv6 = false;
    firewall = {
      enable = true;
    };
    extraHosts = ''
      0.0.0.0 apresolve.spotify.com
      192.168.195.1 unifi.local
    '';
  };
  nix.settings = {
    max-jobs = 2;
    cores = 8;
  };
  services = {
    pcscd = {
      enable = true;
    };
    zfs = {
      trim = {
        enable = true;
      };
    };
    fwupd = {
      enable = true; # plasma
    };
    lact = {
      enable = true;
    };
  };
  environment = {
    systemPackages = with pkgs; [
      protonup-ng
      playerctl
      rocmPackages.rocm-smi
      rocmPackages.rocminfo
      mangohud
      vkbasalt
      protontricks
    ];
    sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    };
  };
  hardware = {
    enableRedistributableFirmware = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    cpu = {
      intel = {
        updateMicrocode = true;
      };
    };
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    amdgpu = {
      initrd = {
        enable = true;
      };
      opencl = {
        enable = true;
      };
      overdrive = {
        enable = true;
      };
    };
    keyboard = {
      qmk = {
        enable = true;
      };
    };
  };
  programs = {
    steam = {
      enable = true;
      gamescopeSession = {
        enable = true;
      };
    };
    gamemode = {
      enable = true;
      settings = {
        general = {
          desiredgov = "performance";
          desiredprof = "performance";
          renice = 5;
        };
      };
    };
  };
  system.stateVersion = "25.05";
  nix = {
    package = unstableSmall.nix;
  };
}
