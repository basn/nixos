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
 stylix = {
   targets = {
     starship = {
       enable = false;
     };
   };
 };
 home = {
    packages = with pkgs; [ signal-desktop orca-slicer ];
  };
}
