{ config, ... }:
{
  hardware = {
    graphics = {
      enable = true;
    };
    nvidia = {
      enabled = true;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
      open = true;
      modesetting = {
        enable = true;
      };
    };
  };
}
