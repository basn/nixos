{ pkgs, ... }:
{
  imports = [ ./fastfetch.nix ];
  programs = { 
    home-manager = {
      enable = true;
    };
  };
  home = {
    enableNixpkgsReleaseCheck = false;
    username = "basn";
    homeDirectory = "/home/basn";
    stateVersion = "24.11";
  };
}
