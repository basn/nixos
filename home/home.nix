{ pkgs, libs, ... }:
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
      settings = pkgs.lib.importTOML ./starship/blue.toml;
    };
    nvf = {
      enable = true;
      settings = {
        vim = {
          theme = {
            enable = true;
            name = "onedark";
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
