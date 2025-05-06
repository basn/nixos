{ config, pkgs, ...}:
{
  home = {
    username = "basn";
    homeDirectory = "/home/basn";
    packages = [ 
    ];
    sessionVariables = {
    };
    stateversion = "24.11";
  };
  programs = {
    home-manager = {
      enable = true;
    };
  };
}

