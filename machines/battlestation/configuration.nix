{ config, pkgs, ... }:
{
  imports = [ ../../common/common.nix ./hyprland.nix ./ollama.nix ];
  boot = {
    initrd = {
      availableKernelModules = [ "vmd" "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
      kernelModules = [ ];
    };
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
      };
    };
    kernel = {
    };
    kernelModules = [ "kvm-intel" ];
    kernelPackages = pkgs.linuxPackages_zen;
  };
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/b37712b5-bbc0-4bb3-99b6-75190a75b1a9";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/E012-C83B";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    }; 
  };
  swapDevices = [ ];
  networking = {
    hostName = "battlestation";
    networkmanager.enable = true;
  };
  services = {
      displayManager = {
      sddm = {
        enable = true;
        wayland = {
          enable = true;
        };
      };
    };
    desktopManager = {
      plasma6 = {
        enable = true;
      };
      cosmic =  {
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
  };
  security.rtkit.enable = true;
  users.users.basn = {
    isNormalUser = true;
    description = "Fredrik Bergstrom";
    extraGroups = [ "networkmanager" "wheel" "gamemode" "input"];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };
  programs.firefox.enable = true;
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    neovim
    nh
    discord
    spotify
    protonup
    ghostty
    google-chrome
    orca-slicer
  ];
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
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
    };
  };
  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS =
      "\${HOME}/.steam/root/compatibilitytools.d";
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
        gpu = {
          nv_powermizer_mode = 1;
        };
      };
    };
    chromium = {
      enable = true;
    };
  };
  fonts.packages = with pkgs; [
    meslo-lgs-nf
  ];
  system = {
      autoUpgrade = {
      flake = "github:basn/nixos";
      enable = true;
    };
    stateVersion = "25.05";
  };
}
