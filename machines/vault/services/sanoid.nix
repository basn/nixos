{ ... }:
{
  services.sanoid = {
    enable = true;
    templates.backup = {
      hourly = 36;
      daily = 30;
      monthly = 3;
      autoprune = true;
      autosnap = true;
    };
    datasets = {
      "storage/nas" = {
        useTemplate = [ "backup" ];
      };
      "storage/berget" = {
        useTemplate = [ "backup" ];
      };
    };
  };
}
