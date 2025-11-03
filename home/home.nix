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
    fish = {
      enable = true;
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
      enableFishIntegration = true;
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
