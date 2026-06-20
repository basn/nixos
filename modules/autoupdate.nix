{ lib, config, ... }:
let
  cfg = config.system.flakeupdate;
in
{
  options.system.flakeupdate = {
    enable = lib.mkEnableOption "automatic flake updates settings";
  };

  config = lib.mkIf cfg.enable {
    system.autoUpgrade = {
      enable = true;
      flake = "git+https://codeberg.org/basn/nixos";
      randomizedDelaySec = "30m";
    };
  };
}
