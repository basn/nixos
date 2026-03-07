{ pkgs, ... }:
{
  hjem = {
    users = {
      basn = {
        packages = [ pkgs.mangohud ];
        files = {
          ".config/MangoHud/MangoHud.conf".source = ./configs/MangoHud.conf;
        };
      };
    };
  };
}
