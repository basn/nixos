{ config, pkgs, ... }:
{
  imports = [ ../../common/common.nix ./qmk.nix ];
  boot = {
    initrd = {
      availableKernelModules = [ "vmd" "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
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
      requestEncryptionCredentials = true;
    };
    supportedFilesystems = [ "zfs" ];
    kernelModules = [ "kvm-intel" ];
    kernelPackages = pkgs.linuxPackages_zen;
  };
  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
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
      allowedTCPPorts = [ 22 ];
    };
  };
  services = {
      displayManager = {
      sddm = {
        enable = true;
        #package = pkgs.kdePackages.sddm;
        extraPackages = with pkgs; [
          sddm-astronaut
        ];
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
    xserver ={
      enable = true;
      xkb = {
        layout = "se";
        variant = "";
      }; 
      videoDrivers = ["nvidia"];
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
    tailscale = {
      enable = true;
    };
  };
  security = {
    rtkit = {
      enable = true;
    };
  };
  users.users.basn = {
    isNormalUser = true;
    description = "Fredrik Bergstrom";
    extraGroups = [ "networkmanager" "wheel" "gamemode" "input" "dialout" ];
  };
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
  environment = {
    systemPackages = with pkgs; [
      neovim
      nh
      discord
      spotify
      protonup
      ghostty
      google-chrome
      kdePackages.dolphin
      sddm-astronaut
      kdePackages.qtmultimedia
      vivaldi
      webcord
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
  fonts.packages = with pkgs; [
    meslo-lgs-nf
  ];
  xdg = {
    portal = {
      enable = true;
      xdgOpenUsePortal = true;
      config = {
        common.default = [ "hyprland" ];
        hyprland.default = [ "hyprland" "gtk" ];
      };
      extraPortals = with pkgs; [ pkgs.xdg-desktop-portal-gtk xdg-desktop-portal-hyprland ];
    };
  };
  system = {
      autoUpgrade = {
      flake = "github:basn/nixos";
      enable = true;
    };
    stateVersion = "25.05";
  };
}
