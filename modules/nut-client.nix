{
  config,
  lib,
  ...
}:
let
  cfg = config.basn.nutClient;
in
{
  options.basn.nutClient = {
    enable = lib.mkEnableOption "the UniFi UPS Tower NUT client";

    passwordFile = lib.mkOption {
      type = lib.types.str;
      description = "Path to the NUT monitor password, provisioned outside the Nix store.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "basn";
      description = "NUT monitor username configured on the UPS.";
    };
  };

  config = lib.mkIf cfg.enable {
    power.ups = {
      enable = true;
      mode = "netclient";
      upsmon = {
        enable = true;
        monitor.stockfallet = {
          system = "stockfallet@192.168.195.138:3493";
          powerValue = 1;
          user = cfg.user;
          passwordFile = cfg.passwordFile;
          type = "secondary";
        };
      };
    };
  };
}
