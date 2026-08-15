{ ... }:
{
  system.autoUpgrade = {
    enable = true;
    flake = "git+https://github.com/basn/nixos";
  };
}
