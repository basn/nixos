{ pkgs, ... }:
{
  imports = [ ./users.nix ./stylix.nix ];
  time = {
    timeZone = "Europe/Stockholm";
  };
  networking = {
    timeServers = [ "sth1.ntp.se" "sth2.ntp.se" "gbg1.ntp.se" "gbg2.ntp.se" ];
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
    defaultUserShell = pkgs.fish;
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
      fish
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
      enable = false;
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
    fish = {
      enable = true;
    };
    nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since 4d --keep 3";
      };
      flake = "/home/basn/nixos";
    };
  };
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };
  };
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
}
