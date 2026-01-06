{ pkgs, ... }:
{
  hjem = {
    users = {
      basn = {
        packages = [ pkgs.fastfetch ];
        files = {
          ".config/fastfetch/config.jsonc".source = ./configs/fastfetch.jsonc;
        };
      };
    };
  };
}
