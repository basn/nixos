{config, lib, pkgs, ...}:
{
  environment.systemPackages = with pkgs; [
    uptime-kuma
  ];
 services = {
   uptime-kuma = {
     enable = true;
     settings = {
       PORT = "9090";
     };
   };
 };
}
