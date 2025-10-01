{ pkgs, ... }:
{
 imports = [
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
