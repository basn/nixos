{ pkgs, ... }:
{
  hjem = {
    users = {
      basn = {
        packages = with pkgs; [
          noctalia
          satty
        ];
      };
    };
  };
}
