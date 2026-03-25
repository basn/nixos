{ pkgs, ... }:
{
  imports = [
    ./browsers.nix
    ./ghostty.nix
    ./fastfetch.nix
    ./mangohud.nix
    ./mangowc.nix
    ./noctalia.nix
    ./git.nix
  ];
  hjem = {
    users = {
      basn = {
        enable = true;
        directory = "/home/basn";
        packages = with pkgs; [
          spotify
          discord
          vesktop
          equibop
          signal-desktop
          orca-slicer
          bitwarden-desktop
          virt-manager
          libvirt
        ];
        clobberFiles = true;
      };
    };
  };
}
