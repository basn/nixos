{ pkgs, ... }:
{
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
            keys = [ 
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICdxg/zlW4GiU6kRJcTQ6UYEbF07uBJWD5zhcm6gk//T basn@battlestation" 
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJaybi1pQnJp1dE/LhhPGiy94000SpKG6q3Qg0UjryOi evl755@KX4H4MFHW1"
            ];
          };
        };
      };
    };
  };
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
      neofetch
      sops
      git
      ipcalc
      nh
      dust
    ];
  };
  programs = {
    mtr = {
      enable = true;
    };
    neovim = {
      defaultEditor = true;
      enable = true;
      viAlias = true;
      vimAlias = true;
    };
    zsh = {
      enable = true;
      promptInit = "eval \"$(oh-my-posh init zsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/refs/heads/main/themes/blue-owl.omp.json')\"";
      syntaxHighlighting = {
        enable = true;
      };
      histSize = 10000;
      enableLsColors = true;
      enableCompletion = true;
    };
    fzf = {
      keybindings = true;
      fuzzyCompletion = true;
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
}
