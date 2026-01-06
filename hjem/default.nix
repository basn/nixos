{ pkgs, ... }:
{
  imports = [
    ./fastfetch.nix
    ./vivaldi.nix
    ./ghostty.nix
  ];
  hjem = {
    users = {
      basn = {
        enable = true;
        directory = "/home/basn";
        packages = with pkgs; [
          signal-desktop
          orca-slicer
          bitwarden-desktop
        ];
        clobberFiles = true;
      };
    };
  };
}
