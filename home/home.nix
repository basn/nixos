{ pkgs, ... }:
{
  imports = [ ./fastfetch.nix ];
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
    fish = {
      enable = true;
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
    };
    git = {
      enable = true;
      userName = "Fredrik Bergström";
      userEmail = "basn@lan2k.org";
    };
    starship = {
      enable = true;
      settings = {
        add_newline = true;
        command_timeout = 1300;
        scan_timeout = 50;
        format = "$all$nix_shell$nodejs$lua$golang$rust$php$git_branch$git_commit$git_state$git_status\n$username$hostname$directory";
        character = {
          success_symbol = "[](bold green) ";
          error_symbol = "[✗](bold red) ";
        };
      };
    };
    nvf = {
      enable = true;
      settings = {
        vim = {
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
    packages = with pkgs; [ whois asn gh nixpkgs-review ];
  };
}
