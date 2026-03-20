{ config, ... }:
{
  hardware = {
    graphics = {
      enable = true;
    };
    nvidia = {
      enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.beta;
      open = true;
      modesetting = {
        enable = true;
      };
    };
  };
}
