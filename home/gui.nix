{ pkgs, ... }:
{
 imports = [
   ./home.nix
 ];
 programs = {
   ghostty = {
     enable = true;
      settings = {
        font-family = "MesloLGMDZ Nerd Font";
        font-family-bold = "MesloLGMDZ Nerd Font";
        font-size = 12;
        theme = "iTerm2 Dark Background";
        shell-integration = "fish";
        shell-integration-features = "sudo";
      };
   };
 };
 home = {
    packages = with pkgs; [ signal-desktop orca-slicer equibop ];
  };
}
