{ ... }:
{
  system.autoUpgrade = {
    enable = true;
    flake = "git+https://github.com/basn/nixos";
    operation = "switch";
    dates = "02:00";
    randomizedDelaySec = "4h";
    fixedRandomDelay = true;
    persistent = true;
    allowReboot = false;
  };
}
