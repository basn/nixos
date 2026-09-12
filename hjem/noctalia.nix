{ pkgs, ... }:
{
  hjem = {
    users = {
      basn = {
        packages = with pkgs; [
          noctalia-shell
          satty
        ];
      };
    };
  };
}
