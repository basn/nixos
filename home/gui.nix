{ pkgs, ... }:
{
 imports = [
   ./hyprland/default.nix
   ./home.nix
 ];
 programs = {
   ghostty = {
     enable = true; 
   };
 };
 home = {
    packages = with pkgs; [ signal-desktop orca-slicer ];
  };
}
