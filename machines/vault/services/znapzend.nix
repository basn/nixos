{ ... }:
{
  services.znapzend = {
    enable = true;
    autoCreation = true;
    zetup = {
      "nas" = {
        enable = true;
        recursive = true;
        mbuffer.enable = false;
        plan = "1d=>4h,1w=>1d";
        timestampFormat = "%Y%m%d%H%M%SZ";
        destinations = {
          "nixos-sov" = {
            dataset = "storage/nas";
            plan = "1w=>1d";
            host = "syncoid@nixos-sov";
          };
        };
      };
    };
  };
}
