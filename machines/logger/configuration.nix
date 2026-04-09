{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./sops.nix
    ./services/logging.nix
    ./services/nginx.nix
  ];

  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs = {
      extraPools = [ "tank" ];
      devNodes = "/dev/disk/by-id";
    };
    loader = {
      systemd-boot = {
        enable = true;
      };
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "logger";
    hostId = "73b2a9c4";
    useDHCP = true;
    enableIPv6 = false;
    firewall = {
      allowedTCPPorts = [
        22
        443
        1514
      ];
      allowedUDPPorts = [ 1514 ];
    };
  };

  services = {
    openssh.enable = true;
    qemuGuest.enable = true;
    zfs.autoScrub.enable = true;
  };

  virtualisation.vmVariant = {
    virtualisation = {
      memorySize = 8192;
      cores = 4;
      diskSize = 120 * 1024;
    };
  };

  system = {
    stateVersion = "25.11";
    autoUpgrade = {
      enable = true;
      flake = "github:basn/nixos";
    };
  };

  environment.systemPackages = with pkgs; [ cachix ];
}
