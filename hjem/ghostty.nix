{ pkgs, ... }:
{
  hjem = {
    users = {
      basn = {
        packages = [ pkgs.ghostty ];
        files = {
          ".config/ghostty/config".source = ./configs/ghostty.conf;
        };
      };
    };
  };
}
