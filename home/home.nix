{ config, pkgs, ... }:
let
  themeFile = ./powerlevel10k_modern.omp.json;
  themePath = "${config.home.homeDirectory}/.config/oh-my-posh/powerlevel10k_modern.omp.json";
in {
  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    enableLsColors = true;
    histSize = 10000;

    initExtra = ''
      eval "$(oh-my-posh init zsh --config ${themePath})"
    '';
  };

  programs.fzf = {
    enable = true;
    keybindings = true;
    fuzzyCompletion = true;
  };

  home.packages = with pkgs; [
    oh-my-posh
  ];

  home.file.".config/oh-my-posh/powerlevel10k_modern.omp.json".source = themeFile;

  home.stateVersion = "24.11";
}
