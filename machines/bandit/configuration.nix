{ inputs, config, lib, pkgs, ... }:
{
  imports = [ 
    ./hardware-configuration.nix
    ./services/plex.nix
    ./services/sonarr.nix
    ./services/radarr.nix
    ./services/prowlarr.nix
    ./services/nginx.nix
    ./services/bittorrent.nix
    ./services/unpackerr.nix
    ./rclone/rclone.nix
    ./services/jellyfin.nix
    ./sops.nix
    ../../common/common.nix
    ./services/immich.nix
    inputs.sops_nix.nixosModules.sops
  ];
  boot = {
    kernelModules = [ "kvm-intel" "r8169" ];
    kernelParams = [ "ip=dhcp" ];
    supportedFilesystems = [ "zfs" ];
    initrd = {
      kernelModules = [ "r8169" ];
      availableKernelModules = [ "r8169" "vmd" "xhci_pci" "mpt3sas" "ahci" "usb_storage" "sd_mod" ];
      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 2222;
          hostKeys = [ "/root/hostkey.ssh" ];
          authorizedKeys = with lib; concatLists (mapAttrsToList (name: user: if elem "wheel" user.extraGroups then user.openssh.authorizedKeys.keys else []) config.users.users);
        };
        postCommands = ''
          zpool import osdisk
          echo "zfs load-key -a; killall zfs" >> /root/.profile
        '';
      };
    };
    zfs = {
      devNodes = "/dev/disk/by-id";
    };
    loader = {
      grub = {
        enable = true;
        zfsSupport = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        mirroredBoots = [
          { devices = [ "nodev"]; path = "/boot1"; }
          { devices = [ "nodev"]; path = "/boot2"; }
        ];
      };
    };
  };
  fileSystems = {
    "/" ={
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
      neededForBoot = true;
    };
    "/data/files" = {
      device = "data/files";
      fsType = "zfs";
      encrypted.keyFile = "/root/zfs-data.key";
    };
    "/data2/files" = {
      device = "data2/files";
      fsType = "zfs";
      encrypted.keyFile = "/root/zfs-data2.key";
    };
    "/boot1" = {
      device = "/dev/disk/by-uuid/7821-EDA9";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };
    "/boot2" = {
      device = "/dev/disk/by-uuid/7824-6948";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };
  };
  networking = {
    interfaces = {
       enp5s0 = {
        useDHCP = true;
       };
    };
    nameservers = [ "10.1.1.8" ];
    enableIPv6  = false;
    timeServers = [ "ntp1.sp.se" ];
    hostName = "bandit"; 
    hostId = "4c79e250";
    firewall = { 
      enable = true;
      allowedTCPPorts = [ 22 80 ];
    };
  };
  environment = {
    systemPackages = with pkgs; [
      rclone
    ];
  };
  services = {
    openssh = {
      enable = true;
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
  };
  powerManagement = {
    powertop = {
      enable = true;
    };
  };
  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vpl-gpu-rt
	intel-ocl
      ];
    };
    cpu = {
      intel = {
        updateMicrocode = true;
      };
    };
  };
  system = {
    stateVersion = "24.05";
    autoUpgrade = {
      flake = "github:basn/nixos";
      enable = true;
    };
  };
}
