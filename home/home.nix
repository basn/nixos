{ pkgs, ... }:
{
  imports = [ ./fastfetch.nix ./nvf.nix ];
  services = {
    ssh-agent = {
      enable = true;
    };
  };
  programs = { 
    home-manager = {
      enable = true;
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
      settings = {
        user = {
          Name = "Fredrik Bergström";
          Email = "basn@lan2k.org";
        };
      };
    };
    starship = {
      enable = true;
      settings = pkgs.lib.importTOML ./starship/blue.toml;
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
