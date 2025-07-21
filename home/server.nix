{ pkgs, ... }:
{
 imports = [
   ./home.nix
 ];
  programs = {
    nvf = {
      settings = {
        vim = {
          theme = {
            enable = true;
            name = "onedark";
          };
        };
      };
    };
  };
}
