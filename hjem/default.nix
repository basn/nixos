{ pkgs, ... }:
{
  imports = [
    ./browsers.nix
    ./ghostty.nix
    ./fastfetch.nix
    ./mangohud.nix
    ./umbriel.nix
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
          equibop
          signal-desktop
          orca-slicer
          virt-manager
          libvirt
        ];
        clobberFiles = true;
      };
    };
  };
}
