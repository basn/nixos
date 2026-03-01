{
  config,
  pkgs,
  unstableSmall,
  ...
}:
{
  swapDevices = [ { device = "/dev/zvol/osdisk/swap"; } ];
  imports = [ ../../common/common.nix ];
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
      #package = config.boot.kernelPackages.zfs_cachyos;
      requestEncryptionCredentials = true;
    };
    supportedFilesystems = [ "zfs" ];
    kernelModules = [ "kvm-intel" ];
    #kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-x86_64-v3;
    kernelPackages = unstableSmall.linuxPackages_zen;
    kernelParams = [
      "split_lock_detect=off"
      "amdgpu.mes=0"
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
      videoDrivers = [ "amdgpu" ];
      xkb = {
        layout = "se";
        variant = "nodeadkeys";
        model = "pc105";
      };
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
      wireplumber.extraConfig = {
        "50-fosi-k7-pro" = {
          "monitor.alsa.rules" = [
            {
              matches = [ { "device.name" = "~alsa_card.usb-Fosi_Audio_Fosi_Audio_K7.*"; } ];

              actions = {
                update-props = {
                  # Make this device preferred
                  "priority.session" = 2000;
                  "priority.driver" = 2000;

                  # Force audio format / channels
                  "audio.format" = "S32LE";
                  "audio.channels" = 2;
                  "audio.position" = [
                    "FL"
                    "FR"
                  ];

                  # Default rate
                  "audio.rate" = 192000;

                  # Allow full capability range
                  "audio.allowed-rates" = [
                    44100
                    48000
                    88200
                    96000
                    176400
                    192000
                    352800
                    384000
                    705600
                    768000
                  ];

                  # Disable DSD unless explicitly requested
                  "api.alsa.disable-dsd" = true;

                  # Optional: force headroom and period size if needed
                  "api.alsa.headroom" = 512;
                };
              };
            }
          ];
        };
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
    lact = {
      enable = false;
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
      equibop
      rocmPackages.rocm-smi
      rocmPackages.rocminfo
      teamspeak6-client
      mangohud
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
    amdgpu = {
      initrd = {
        enable = true;
      };
      opencl = {
        enable = true;
      };
      overdrive = {
        enable = false;
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
        };
        gpu = {
          #nv_powermizer_mode = 1;
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
