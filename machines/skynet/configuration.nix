{ ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot = {
    zfs = {
      devNodes = "/dev/disk/by-path";
      forceImportRoot = false;
    };
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    hostName = "skynet";
    hostId = "5018a94f";
    useDHCP = false;
    enableIPv6 = false;
    interfaces.ens33.ipv4.addresses = [
      {
        address = "10.136.48.5";
        prefixLength = 24;
      }
    ];
    defaultGateway = "10.136.48.1";
    nameservers = [ "8.8.8.8" ];
    firewall = {
      enable = true;
      checkReversePath = "strict";
    };
  };

  virtualisation.vmware.guest.enable = true;

  # Select the NVIDIA driver module without enabling an X server.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
  hardware.nvidia = {
    open = true;
    nvidiaSettings = false;
  };

  # Defer notifications until Skynet has SOPS authorization.
  basn.nixosUpgradeNotify.enable = false;
  services.zfs.autoScrub.enable = true;

  services.openssh.settings.PasswordAuthentication = false;

  system.stateVersion = "26.11";
}
