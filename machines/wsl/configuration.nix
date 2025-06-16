# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, ... }:

{
  imports = [
   ../../common/common.nix
  ];
  environment = {
    systemPackages = with pkgs; [
    ];
  };
  users = {
    users = {
      basn = {
        shell = pkgs.zsh;
      };
      root = {
        shell = pkgs.zsh;
      };
    };
  };
  wsl = {
    enable = true;
    defaultUser = "basn";
  };
  system.stateVersion = "24.11"; # Did you read the comment?
}
