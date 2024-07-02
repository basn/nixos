# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./services/podman.nix
      ./services/blocky.nix
      ./services/nginx.nix
#      ./services/unbound.nix
    ];

  boot = {
    zfs = {
      extraPools = [ "tank" ];
      devNodes = "/dev/disk/by-path";
    };
    loader.grub = {
      enable = true;
      zfsSupport = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      mirroredBoots = [
        { devices = [ "nodev"]; path = "/boot"; }
      ];
    };
    kernel = {
       sysctl = {
         "net.core.rmem_default" = 2000000;
         "net.core.wmem_max" = 2000000;
       };
    };
  };

  nixpkgs.config.allowUnfree = true;
  time.timeZone = "Europe/Stockholm";
  networking = {
    interfaces = {
      eth0.ipv4.addresses = [
        {
          address = "10.1.1.8";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = "10.1.1.1";
    nameservers = [ "10.1.1.2" ];
    hostId = "629e8a9b";
    enableIPv6  = false;
    hostName = "services";
    timeServers = [ "ntp1.sp.se" ];
  };
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "sv-latin1";
  };

  users.users.basn = {
     isNormalUser = true;
     extraGroups = [ "wheel" ];
     openssh.authorizedKeys.keys = [
       "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEHXMJeF4KZ+0ZVJCMyV62Vm4UdbwPj/o68hAYJNFMcx basn@bandit"
       "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICdxg/zlW4GiU6kRJcTQ6UYEbF07uBJWD5zhcm6gk//T basn@battlestation"
     ];
  };
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    vim
    wget
    open-vm-tools-headless
    podman
    btop
    dysk
    mtr
    blocky
    neovim
    nginx
    unzip
    screen
    nmap
  ];

  programs = {
    mtr.enable = true;
    vim = {
      package = pkgs.vim-full;
      defaultEditor = true;
    };
  };
  services = {
    openssh.enable = true;
    zfs.autoScrub.enable = true;
    mysql = {
      enable = true;
      package = pkgs.mariadb;
    };
  };
  virtualisation.vmware.guest.enable = true;
  # Other
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Open ports in the firewall.
  networking = {
    firewall = {
      allowedTCPPorts = [ 22 80 443 3000 3306 8080 8686 8772 9080 9443 ];
      allowedTCPPortRanges = [
        { from = 8081; to = 8085; }
        { from = 9600; to = 9603; }
      ];
      allowedUDPPorts = [ 53 69 3478 10001 ];
      allowedUDPPortRanges = [
        { from = 9600; to = 9603; }
      ];
    };
  };
  # Or disable the firewall altogether.
  #networking.firewall.enable = false;
  system.stateVersion = "23.11"; # Did you read the comment?

}
