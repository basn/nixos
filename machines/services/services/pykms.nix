{config, lib, pkgs, ...}:
{
  environment.systemPackages = with pkgs; [
    pykms
  ];
 services = {
   pykms = {
     enable = true;
     port = 1688;
     openFirewallPort = true;
   };
 };
}
