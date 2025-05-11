{config, lib, pkgs, ...}:
{
 networking.extraHosts =
  ''
    10.1.1.8 services.basn.se
    192.168.180.10 bandit.basn.se
  '';
}
