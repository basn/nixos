{ ... }:
{
  services.znapzend = {
    enable = true;
    autoCreation = true;
    pure = true;
    zetup = {
      "tank/vaultwarden" = {
        enable = true;
        recursive = true;
        mbuffer.enable = false;
        plan = "1d=>4h,1w=>1d";
        timestampFormat = "%Y-%m-%d-%H%M%S";
        destinations = {
          "vault" = {
            dataset = "storage/backup";
            plan = "1w=>1d";
            host = "zfsbackup@vault";
          };
        };
      };
    };
  };
}
