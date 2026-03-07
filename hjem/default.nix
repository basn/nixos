{ pkgs, ... }:
{
  imports = [
    ./vivaldi.nix
    ./ghostty.nix
    ./fastfetch.nix
    ./mangohud.nix
    ./git.nix
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
