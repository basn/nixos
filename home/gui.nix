{ ... }:
{
 imports = [
   ./hyprland.nix
   ./home.nix
   ./vivaldi.nix
 ];
 programs = {
   ghostty = {
     enable = true; 
   };
 };
}
