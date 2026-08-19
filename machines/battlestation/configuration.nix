{
  config,
  lib,
  pkgs,
  unstableSmall,
  ...
}:
let
  mangoPackage = pkgs.mango;

  mangoNoctaliaLauncher = pkgs.writeShellScriptBin "mango-noctalia-session" ''
    set -eu
    export XDG_CURRENT_DESKTOP=mango:wlroots
    export XDG_SESSION_DESKTOP=mango
    export XDG_SESSION_TYPE=wayland

    ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd \
      DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE
    ${pkgs.systemd}/bin/systemctl --user import-environment \
      DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE

    cfg="$HOME/.config/mango/config.conf"
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
        Comment=Mango with Noctalia shell
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

in

{
  imports = [
    ./cachyos-proton.nix
    ./opencode.nix
    ./specialisation.nix
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
    extraHosts = "0.0.0.0 apresolve.spotify.com";
  };
  nix.settings = {
    max-jobs = 2;
    cores = 8;
  };
  services = {
    ollama = {
      enable = true;
      package = pkgs.ollama-rocm;
      loadModels = [ "qwen3:8b" ];
      environmentVariables = {
        # Keep the server available locally, but release its model and VRAM
        # shortly after the last request so gaming has the whole GPU.
        OLLAMA_KEEP_ALIVE = "5m";
        OLLAMA_MAX_LOADED_MODELS = "1";
        OLLAMA_NUM_PARALLEL = "1";
        OLLAMA_CONTEXT_LENGTH = "8192";
        OLLAMA_NO_CLOUD = "1";
      };
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
  hjem.users.basn.files.".config/fish/conf.d/codex-nix.fish".source =
    pkgs.writeText "codex-nix.fish" ''
      # Run Codex with the runtime tools required by its sandbox and MCP servers.
      function codex-nix --description 'Run Codex with Nix-provided Bubblewrap, Node.js, Python, and uv'
          nix shell --inputs-from /home/basn/nixos nixpkgs#bubblewrap nixpkgs#nodejs nixpkgs#python3 nixpkgs#uv -c bash -c 'export UV_PYTHON="$(command -v python3)"; exec npx -y @openai/codex -c "mcp_servers.nixos.command=\"nix\"" -c "mcp_servers.nixos.args=[\"run\", \"github:utensils/mcp-nixos\", \"--\"]" "$@"' codex-nix $argv
      end
    '';
  environment = {
    systemPackages = with pkgs; [
      protonup-ng
      sddm-astronaut
      playerctl
      grim
      slurp
      wl-clipboard
      rocmPackages.rocm-smi
      rocmPackages.rocminfo
      mangohud
      vkbasalt
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
    mango = {
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
  system.stateVersion = "25.05";
  nix = {
    package = unstableSmall.nix;
  };
}
