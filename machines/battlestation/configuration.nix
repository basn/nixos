{
  config,
  pkgs,
  unstableSmall,
  ...
}:
let
  monadoPimax = pkgs.monado.overrideAttrs (oldAttrs: {
    version = "25.1.0-pimax-16792a6";
    src = pkgs.fetchFromGitLab {
      domain = "gitlab.freedesktop.org";
      owner = "Coreforge";
      repo = "monado";
      rev = "16792a6f26210faca082d192a8fa9fbf625ab1d9";
      hash = "sha256-M7bjfHS4h0GQ/77PuIxEVvhFZl4dDPVas19/oSfoGCk=";
    };
    patches = [ ];
    meta = oldAttrs.meta // {
      description = "Open source XR runtime with Coreforge Pimax P2 support";
    };
  });

  pimaxDistortion = pkgs.fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "othello7";
    repo = "pimax-distortion";
    rev = "a64c75ed9f4f3bd71847e6daa4b882e38bb5cb07";
    hash = "sha256-33cimiRQgJkL9xj7Y7cJgiCdRXGqFG9qqdNvx4gm5i8=";
  };

  mangoPackage = pkgs.mango or pkgs.mangowc;

  mangoNoctaliaLauncher = pkgs.writeShellScriptBin "mango-noctalia-session" ''
    set -eu
    export XDG_CURRENT_DESKTOP=mango:wlroots
    export XDG_SESSION_DESKTOP=mango
    export XDG_SESSION_TYPE=wayland

    ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd \
      DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE
    ${pkgs.systemd}/bin/systemctl --user import-environment \
      DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE

    cfg="$HOME/.config/mangowc/mangowc.conf"
    if [ -f "$cfg" ]; then
      exec ${mangoPackage}/bin/mango -c "$cfg" -s ${pkgs.noctalia-shell}/bin/noctalia-shell
    else
      exec ${mangoPackage}/bin/mango -s ${pkgs.noctalia-shell}/bin/noctalia-shell
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
        DesktopNames=mango;wlroots
      '')
    ];
    passthru.providedSessions = [ "mango-noctalia" ];
  };

  baseUdevRules = ''
    # Prevent autosuspend on Fosi Audio K7 USB DAC to avoid audio crackle/dropouts.
    ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="152a", ATTR{idProduct}=="889b", TEST=="power/control", ATTR{power/control}="on"
    ACTION=="add|change", SUBSYSTEM=="usb", ATTR{idVendor}=="152a", ATTR{idProduct}=="889b", TEST=="power/autosuspend_delay_ms", ATTR{power/autosuspend_delay_ms}="-1"
    # Prevent autosuspend on Elgato Wave XLR to avoid mute/unmute wakeup glitches.
    ACTION=="add|change", SUBSYSTEM=="usb", ATTRS{product}=="Wave XLR", TEST=="power/control", ATTR{power/control}="on"
    ACTION=="add|change", SUBSYSTEM=="usb", ATTRS{product}=="Wave XLR", TEST=="power/autosuspend_delay_ms", ATTR{power/autosuspend_delay_ms}="-1"
  '';

  vrKernelPatches = [
    {
      name = "pimax-non-desktop-edid-quirks";
      patch = pkgs.fetchurl {
        url = "https://gist.githubusercontent.com/TayouVR/60e3ee5f95375827a66a8898bea02bec/raw/c85135c8d8821ebb2fa85629d837a41de57e12ef/pimax.patch";
        hash = "sha256-xD8mUZne3MDFDt4jstsBv5bG7fWSejV4LEAKB3GWdAY=";
      };
    }
    {
      name = "pimax-edid-checksum-fixup";
      patch = pkgs.fetchurl {
        url = "https://gist.githubusercontent.com/Coreforge/59ed3548427c999273ec012002461eab/raw/f70df3afd5cccbfc6fb34ef805db41d00dbf4770/ps0002-drm-edid-fix-checksum-errors-in-Pimax-HMD-EDIDs.patch";
        hash = "sha256-faggU9KLVydvdQR8m9V7SUQnwtXs+h9IpNv9BS64qZU=";
      };
    }
  ];

  vrUdevRules = ''
    # Allow Monado's Pimax driver to access P2-series headset control HID.
    SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="0101", MODE="0660", GROUP="input"
    KERNEL=="hidraw*", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="0101", MODE="0660", GROUP="input"
  '';

  vrOpenvrConfig = pkgs.writeText "openvrpaths.vrpath" (
    builtins.toJSON {
      version = 1;
      jsonid = "vrpathreg";
      external_drivers = null;
      config = [ "/home/basn/.local/share/Steam/config" ];
      log = [ "/home/basn/.local/share/Steam/logs" ];
      runtime = [ "${pkgs.xrizer}/lib/xrizer" ];
    }
  );

  vrSteamPackage = pkgs.steam.override {
    extraProfile = ''
      export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1
      unset TZ
    '';
  };
in

{
  imports = [
    ../../common/zfs.nix
    ./cachyos-proton.nix
    ./opencode.nix
  ];

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
      forceImportRoot = false;
    };
    supportedFilesystems = [ "zfs" ];
    kernelModules = [
      "kvm-intel"
      "ntsync"
    ];
    kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-lto-x86_64-v3;
    kernelParams = [
      "split_lock_detect=off"
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
  nix.settings = {
    max-jobs = 2;
    cores = 8;
  };
  services = {
    thermald = {
      enable = true;
    };
    udev = {
      extraRules = baseUdevRules;
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
                  # Apply playback format and adaptive rate behavior on the sink node.
                  "priority.session" = 2000;
                  "priority.driver" = 2000;
                  "audio.format" = "S32LE";
                  "audio.channels" = 2;
                  "audio.position" = [
                    "FL"
                    "FR"
                  ];
                  # Allow rate switching to match source material when possible.
                  "api.alsa.multi-rate" = true;
                  "audio.allowed-rates" = [
                    44100
                    48000
                    88200
                    96000
                    176400
                    192000
                  ];
                };
              };
            }
          ];
        };
        "52-wave-xlr-source-node" = {
          "monitor.alsa.rules" = [
            {
              # Keep Wave XLR capture node active so hardware unmute reliably resumes capture.
              matches = [ { "node.name" = "~alsa_input.usb-.*Wave_XLR.*"; } ];
              actions = {
                update-props = {
                  "session.suspend-timeout-seconds" = 0;
                  "node.pause-on-idle" = false;
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
  specialisation.vr = {
    configuration = {
      boot = {
        kernelPatches = vrKernelPatches;
      };
      services = {
        monado = {
          enable = true;
          package = monadoPimax;
          defaultRuntime = true;
        };
        udev.extraRules = baseUdevRules + vrUdevRules;
      };
      systemd.user.services.monado.environment = {
        STEAMVR_LH_ENABLE = "1";
        IPC_EXIT_WHEN_IDLE = "1";
        PIMAX_HID_RETRY_COUNT = "10";
      };
      hjem.users.basn.files.".config/openvr/openvrpaths.vrpath".source = vrOpenvrConfig;
      hjem.users.basn.files.".config/pimax/meshes".source = "${pimaxDistortion}/meshes";
      environment.systemPackages = with pkgs; [ xrizer ];
      programs.steam.package = vrSteamPackage;
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
      protonup-ng
      sddm-astronaut
      playerctl
      grim
      slurp
      wl-clipboard
      rocmPackages.rocm-smi
      rocmPackages.rocminfo
      mangohud
      protontricks
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
    mangowc = {
      enable = true;
      package = mangoPackage;
    };
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
      flake = "git+https://codeberg.org/basn/nixos";
      enable = true;
    };
    stateVersion = "25.05";
  };
  nix = {
    package = unstableSmall.nix;
  };
}
