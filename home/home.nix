{ config, pkgs, ... }:
let
  themeFile = ./powerlevel10k_modern.omp.json;
  themePath = "${config.home.homeDirectory}/.config/oh-my-posh/powerlevel10k_modern.omp.json";
in {
  programs = { 
    zsh = {
      enable = true;
      autosuggestion = {
        enable = true;
      };
      enableCompletion = true;
      history = {
        size = 10000;
	share = true;
      };
      initExtra = ''
        eval "$(oh-my-posh init zsh --config ${themePath})"
      '';
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    git = {
      enable = true;
      userName = "Fredrik Bergström";
      userEmail = "basn@lan2k.org";
    };
  };

  home = {
    username = "basn";
    homeDirectory = "/home/basn";
    file.".config/oh-my-posh/powerlevel10k_modern.omp.json".source = themeFile;
    stateVersion = "24.11";
    packages = with pkgs; [ oh-my-posh ];
  };
}
