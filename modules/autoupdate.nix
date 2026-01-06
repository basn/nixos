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
      flake = "github:basn/nixos";
      randomizedDelaySec = "30m";
    };
  };
}
