{ ... }:
{
  services.znapzend = {
    enable = true;
    autoCreation = true;
    zetup = {
      "storage/nas" = {
        enable = true;
        recursive = true;
        mbuffer.enable = false;
        plan = "1d=>4h,1w=>1d";
        timestampFormat = "%Y-%m-%d-%H%M%S";
        destinations = {
          "nixos-sov" = {
            dataset = "backup/nas";
            plan = "1w=>1d";
            host = "syncoid@nixos-sov";
          };
        };
      };
      "storage/berget" = {
        enable = true;
        recursive = true;
        mbuffer.enable = false;
        plan = "1d=>4h,1w=>1d";
        timestampFormat = "%Y-%m-%d-%H%M%S";
        destinations = {
          "nixos-sov" = {
            dataset = "backup/berget";
            plan = "1w=>1d";
            host = "syncoid@nixos-sov";
          };
        };
      };
    };
  };
}
