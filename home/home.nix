{ pkgs, ... }:
{
  services = {
    ssh-agent = {
      enable = true;
    };
  };
  programs = { 
    home-manager = {
      enable = true;
    };
    ssh = {
      addKeysToAgent = "yes";
    };
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
    oh-my-posh = {
      enable = true;
      enableZshIntegration = true;
      useTheme = "blue-owl";
    };
    nvf = {
      enable = true;
      settings = {
        vim = {
          lsp = {
            enable = true;
          };
          languages = {
            enableFormat = true;
            enableTreesitter = true;
            enableExtraDiagnostics = true;
            nix = {
              enable = true;
            };
            yaml = {
              enable = true;
            };
            python = {
              enable = true;
            };
          };
          statusline = {
            lualine = {
              enable = true;
            };
          };
          autocomplete = {
            nvim-cmp = {
              enable = true;
            };
          };
        }; 
      };
    };
  };
  home = {
    enableNixpkgsReleaseCheck = false;
    username = "basn";
    homeDirectory = "/home/basn";
    stateVersion = "24.11";
    packages = with pkgs; [ oh-my-posh fastfetch whois ];
  };
}
