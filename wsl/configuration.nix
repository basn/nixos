# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, ... }:

{
  imports = [
  ];
  environment = {
    systemPackages = with pkgs; [
      neovim
      btop
      dysk
      screen
      nmap
      zsh
      zsh-fzf-tab
      zsh-powerlevel10k
      zsh-fzf-history-search
      fzf-zsh
      oh-my-posh
      whois
      ipcalc
    ];
  };
  programs = {
    mtr = {
      enable = true;
    };
    neovim = {
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
  nixpkgs = {
    config = {
      allowUnfree = true;
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
  users = {
    users = {
      basn = {
        shell = pkgs.zsh;
      };
      root = {
        shell = pkgs.zsh;
      };
    };
  };
  wsl = {
    enable = true;
    defaultUser = "basn";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
