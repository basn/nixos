{ config, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
      ../common/common.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "laptop"; 
  networking.networkmanager.enable = true;
  time.timeZone = "Europe/Stockholm";

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
      enable = true;
      displayManager.lightdm.enable = true;
      desktopManager.pantheon.enable = true;
    };
    auto-cpufreq = {
      enable = true;
      battery = {
        govenor = "powersave";
        turbo = "never";
      };
      charger = {
        govenor = "performance";
        turbo = "auto";
      };
    };
  };

  services.xserver.xkb = {
    layout = "se";
    variant = "";
  };

  console.keyMap = "sv-latin1";

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  users.users.basn = {
    isNormalUser = true;
    description = "Fredrik Bergström";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    ];
  };

  programs.firefox.enable = true;
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    ghostty
    neovim
    spotify
    chromium
  ];
  fonts.packages = with pkgs; [
    meslo-lgs-nf
  ];
  powerManagement = {
    enable = true;
  };
  system.stateVersion = "25.05";

}
