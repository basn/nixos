{ config, pkgs, ... }:

let
  hostname = builtins.getEnv "HOSTNAME";
  workmachine = hostname == "bleh";
  themePath = "${config.home.homeDirectory}/.config/oh-my-posh/powerlevel10k_modern.omp.json";
in
{
  imports = [
    (if workmachine then ./work.nix else ./basn.nix)
  ];
  home.shell = pkgs.zsh;
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

  home.file.".config/oh-my-posh/powerlevel10k_modern.omp.json".source =
    ./powerlevel10k_modern.omp.json;

  home.stateVersion = "24.11";
}
