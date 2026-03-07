{ pkgs, ... }:
{
  hjem = {
    users = {
      basn = {
        packages = [ pkgs.git ];
        files = {
          ".gitconfig".source = ./configs/gitconfig;
        };
      };
    };
  };
}
