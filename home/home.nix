{ config, ... }:

{
  home = {
    username = "basn";
    homeDirectory = "/home/basn";
  };
  home.stateVersion = "24.11"; # Keep this unless you know you need a different version
}
