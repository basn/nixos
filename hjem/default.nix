{
  config,
  inputs,
  pkgs,
  system,
  ...
}:
let
  stablePkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  orcaSlicer =
    if config.networking.hostName == "battlestation" then
      stablePkgs.orca-slicer
    else
      pkgs.orca-slicer;
in
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
          equibop
          signal-desktop
          orcaSlicer
          virt-manager
          libvirt
        ];
        clobberFiles = true;
      };
    };
  };
}
