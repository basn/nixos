{ config, pkgs, sops, ... }:

{
  sops = {
    defaultSopsFile = ./secrets/services.yaml;
    age = {
      keyFile = "/home/basn/.config/sops/age/keys.txt";
    };
  };
}
