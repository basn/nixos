{ ... }:
{
  system.autoUpgrade = {
    enable = true;
    flake = "git+https://codeberg.org/basn/nixos";
  };
}
