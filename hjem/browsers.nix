{ pkgs, ... }:
{
  hjem = {
    users = {
      basn = {
        packages = [
          pkgs.vivaldi
          pkgs.chromium
          pkgs.google-chrome
        ];
      };
    };
  };
}
