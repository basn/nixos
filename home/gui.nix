{ pkgs, ... }:
{
 imports = [
   ./hyprland/default.nix
   ./home.nix
   ./vivaldi.nix
 ];
 programs = {
   ghostty = {
     enable = true; 
   };
 };
 home = {
    packages = with pkgs; [ signal-desktop ];
  };
}
