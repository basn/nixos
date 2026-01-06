{ config, pkgs, unstableSmall, ... }:
{
  imports = [
    ../../common/common.nix
  ];
  boot = {
    initrd = {
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
      kernelModules = [ ];
    };
    loader = {
      systemd-boot = {
        enable = true;
      };
      efi = {
        canTouchEfiVariables = true;
      };
    };
    zfs = {
      package = unstableSmall.zfs_unstable;
      requestEncryptionCredentials = true;
    };
    supportedFilesystems = [ "zfs" ];
    kernelModules = [ "kvm-intel" ];
    kernelPackages = unstableSmall.linuxPackages_zen;
    blacklistedKernelModules = [ "noveau" "nova_core" ];
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
  swapDevices = [ ];
  networking = {
    hostName = "battlestation";
    hostId = "121e3eb9";
    interfaces = {
      eno1 = {
        useDHCP = true;
      };
    };
    enableIPv6 = false;
    firewall = {
      enable = true;
    };
    extraHosts = "0.0.0.0 apresolve.spotify.com";
  };
  services = {
    displayManager = {
      sddm = {
        enable = true;
        extraPackages = with pkgs; [ sddm-astronaut ];
        theme = "sddm-astronaut-theme";
        wayland = {
          enable = true;
        };
        settings = {
          Theme = {
            Current = "sddm-astronaut-theme";
          };
        };
      };
    };
    desktopManager = {
      plasma6 = {
        enable = true;
      };
      cosmic = {
        enable = true;
      };
    };
    xserver = {
      enable = true;
      xkb = {
        layout = "se";
        variant = "nodeadkeys";
        model = "pc105";
      };
      videoDrivers = [ "nvidia" ];
    };
    pulseaudio = {
      enable = false;
    };
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse = {
        enable = true;
      };
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
    fwupd = {
      enable = true; # plasma
    };
  };
  security = {
    rtkit = {
      enable = true;
    };
  };
  users.users.basn = {
    extraGroups = [
      "networkmanager"
      "wheel"
      "gamemode"
      "input"
      "dialout"
    ];
  };
  environment = {
    systemPackages = with pkgs; [
      neovim
      nh
      discord
      spotify
      protonup-ng
      ghostty
      google-chrome
      sddm-astronaut
      vivaldi
      vesktop
    ];
    variables = {
      NIXOS_OZONE_WL = "1";
    };
    sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    };
  };
  hardware = {
    enableRedistributableFirmware = true;
    cpu = {
      intel = {
        updateMicrocode = true;
      };
    };
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      modesetting = {
        enable = true;
      };
      powerManagement = {
        enable = true;
      };
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
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
        };
        gpu = {
          nv_powermizer_mode = 1;
        };
        cpu = {
          pin_cores = "0-15";
        };
      };
    };
  };
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [ meslo-lgs-nf ];
  };
  system = {
    autoUpgrade = {
      flake = "github:basn/nixos";
      enable = true;
    };
    stateVersion = "25.05";
  };
}
