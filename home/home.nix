{ config, pkgs, inputs, ... }:
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
      initContent = ''
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
    nvf = {
      enable = true;
      settings = {
        vim = {
          theme = {
            enable = true;
            name = "onedark";
            style = "darker";
          };
          lsp = {
            enable = true;
          };
          languages = {
            nix = {
              enable = true;
            };
            yaml = {
              enable = true;
            };
          };
          statusline = {
            lualine = {
              enable = true;
            };
          };
        }; 
      };
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
