{
  config,
  inputs,
  pkgs,
  unstableSmall,
  ...
}:
let
  stablePkgs = import inputs.nixpkgs {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };

  mangoNoctaliaLauncher = pkgs.writeShellScriptBin "mango-noctalia-session" ''
    set -eu
    cfg="$HOME/.config/mangowc/mangowc.conf"
    if [ -f "$cfg" ]; then
      exec ${pkgs.mangowc}/bin/mango -c "$cfg" -s ${pkgs.noctalia-shell}/bin/noctalia-shell
    else
      exec ${pkgs.mangowc}/bin/mango -s ${pkgs.noctalia-shell}/bin/noctalia-shell
    fi
  '';

  mangoNoctaliaSession = pkgs.symlinkJoin {
    name = "mango-noctalia-session";
    paths = [
      (pkgs.writeTextDir "share/wayland-sessions/mango-noctalia.desktop" ''
        [Desktop Entry]
        Name=Mango (Noctalia)
        Comment=MangoWC with Noctalia shell
        Exec=${mangoNoctaliaLauncher}/bin/mango-noctalia-session
        Type=Application
        DesktopNames=mango
      '')
    ];
    passthru.providedSessions = [ "mango-noctalia" ];
  };
in
{
  swapDevices = [ { device = "/dev/zvol/osdisk/swap"; } ];
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
        configurationLimit = 3;
      };
      efi = {
        canTouchEfiVariables = true;
      };
    };
    zfs = {
      package = config.boot.kernelPackages.zfs_cachyos;
      requestEncryptionCredentials = true;
    };
    supportedFilesystems = [ "zfs" ];
    kernelModules = [ "kvm-intel" ];
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-x86_64-v3;
    #kernelPackages = unstableSmall.linuxPackages_zen;
    kernelParams = [
      "split_lock_detect=off"
      "amdgpu.mes=0"
      "intel_iommu=on"
      "iommu=pt"
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
    networkmanager.enable = true;
    enableIPv6 = false;
    firewall = {
      enable = true;
    };
    extraHosts = "0.0.0.0 apresolve.spotify.com";
  };
  services = {
    thermald = {
      enable = true;
    };
    pcscd = {
      enable = true;
    };
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
        enable = false;
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
        "50-fosi-k7-pro-device" = {
          "monitor.alsa.rules" = [
            {
              matches = [ { "device.name" = "~alsa_card.usb-Fosi_Audio_Fosi_Audio_K7.*"; } ];

              actions = {
                update-props = {
                  # Prefer this card when selecting default audio devices
                  "priority.session" = 2000;
                  "priority.driver" = 2000;

                  # Disable DSD unless explicitly requested
                  "api.alsa.disable-dsd" = true;

                  # Optional: force headroom and period size if needed
                  "api.alsa.headroom" = 512;
                };
              };
            }
          ];
        };
        "51-fosi-k7-pro-node" = {
          "monitor.alsa.rules" = [
            {
              matches = [ { "node.name" = "~alsa_output.usb-Fosi_Audio_Fosi_Audio_K7-00.pro-output-0"; } ];
              actions = {
                update-props = {
                  # Apply playback format/rate on the actual sink node
                  "priority.session" = 2000;
                  "priority.driver" = 2000;
                  "audio.format" = "S32LE";
                  "audio.channels" = 2;
                  "audio.position" = [
                    "FL"
                    "FR"
                  ];
                  "audio.rate" = 192000;
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
      enable = true;
    };
    displayManager.sessionPackages = [ mangoNoctaliaSession ];
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
      protonup-ng
      sddm-astronaut
      playerctl
      grim
      slurp
      wl-clipboard
      rocmPackages.rocm-smi
      rocmPackages.rocminfo
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
    mangowc.enable = true;
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
