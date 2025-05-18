{ inputs, config, lib, pkgs, unstablePkgs, ... }:
{
  imports =
    [ 
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
      ../common/common.nix
      inputs.sops_nix.nixosModules.sops
    ];
  boot = {
    kernelModules = [ "r8169" ];
    kernelParams = [ "ip=dhcp" ];
    initrd = {
      kernelModules = [ "r8169" ];
      availableKernelModules = [ "r8169" ];
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
    proxy = {
      default = "http://100.64.1.1:8080";
    };
    firewall = { 
      enable = true;
      allowedTCPPorts = [ 22 80 ];
      allowedUDPPortRanges = [{ 
                                from = 2302;
                                to = 2320;
			      }];
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
  };
}
