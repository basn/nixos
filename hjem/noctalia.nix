{ pkgs, ... }:
{
  hjem = {
    users = {
      basn = {
        packages = with pkgs; [
          noctalia-shell
        ];
        files = {
          ".config/noctalia/settings.json".source = ./configs/noctalia-settings.json;
        };
      };
    };
  };
}
