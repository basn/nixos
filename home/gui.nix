{ ... }:
{
 imports = [
   ./hyprland.nix
   ./home.nix
 ];
 programs = {
   ghostty = {
     enable = true; 
   };
 };
}
