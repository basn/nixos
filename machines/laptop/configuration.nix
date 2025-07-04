{ pkgs, ... }:
{
  imports =
    [ 
      ./hardware-configuration.nix
      ../../common/common.nix
      ./plasma6.nix
    ];

  boot = {
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
    initrd = {
      supportedFilesystems = [ "zfs" ];
    };
    supportedFilesystems = [ "zfs" ];
    kernelPackages = pkgs.linuxPackages_zen;
  };
  networking = {
    hostName = "laptop"; 
    hostId = "3e25a9f6";
    networkmanager = {
      enable = true;
    };
  };
  time = {
    timeZone = "Europe/Stockholm";
  };
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "sv_SE.UTF-8";
      LC_IDENTIFICATION = "sv_SE.UTF-8";
      LC_MEASUREMENT = "sv_SE.UTF-8";
      LC_MONETARY = "sv_SE.UTF-8";
      LC_NAME = "sv_SE.UTF-8";
      LC_NUMERIC = "sv_SE.UTF-8";
      LC_PAPER = "sv_SE.UTF-8";
      LC_TELEPHONE = "sv_SE.UTF-8";
      LC_TIME = "sv_SE.UTF-8";
    };
  };
  services = {
    xserver = {
      xkb = {
        layout = "se";
        variant = "";
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
    };
  };
  console.keyMap = "sv-latin1";
  security.rtkit.enable = true;
  users.users.basn = {
    isNormalUser = true;
    description = "Fredrik Bergström";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      discord
      chromium
      ghostty
      spotify
    ];
  };
  programs = {
    chromium = {
      enable = true;
    };
  };
  environment.systemPackages = with pkgs; [
    neovim
  ];
  fonts.packages = with pkgs; [
    meslo-lgs-nf
  ];
  powerManagement = {
    enable = true;
  };
  system = {
    stateVersion = "25.05";
  };
}
