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
  time = {
    timeZone = "Europe/Stockholm";
  };
  i18n = { 
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "sv_SE.UTF-8";
      LC_MONETARY = "sv_SE.UTF-8";
    };
  };
  console = {
    font = "Lat2-Terminus16";
    keyMap = "sv-latin1";
  };
  users  = {
    defaultUserShell = pkgs.zsh;
    users = {
      basn = {
        isNormalUser = true;
        extraGroups = [ "wheel" ]; 
        openssh = {
	  authorizedKeys = {
	    keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICdxg/zlW4GiU6kRJcTQ6UYEbF07uBJWD5zhcm6gk//T basn@battlestation" ];
	  };
	};
      };
    };
  };
  #home-manager.users.basn = import ../home/home.nix;
  security = {
    sudo = {
      wheelNeedsPassword = false;
    };
  };
  environment = {
    systemPackages = with pkgs; [
      neovim
      wget
      btop
      dysk
      unzip
      screen
      nmap
      zsh
      zsh-fzf-tab
      zsh-powerlevel10k
      zsh-fzf-history-search
      fzf-zsh
      oh-my-posh
      rclone
      neofetch
      sops
      git
      home-manager
    ];
  };
  programs = {
    mtr = {
      enable = true;
    };
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      defaultEditor = true;
    };
    zsh = {
      enable = true;
      syntaxHighlighting = {
        enable = true;
      };
      promptInit = "eval \"$(oh-my-posh init zsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/refs/heads/main/themes/powerlevel10k_modern.omp.json')\"";
      histSize = 10000;
      enableLsColors = true;
      enableCompletion = true;
    };
    fzf = {
      keybindings = true;
      fuzzyCompletion = true;
    };
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
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
  nixpkgs = {
    config = {
      allowUnfree = true;
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
  };
  system = {
    stateVersion = "24.05";
  };
}
