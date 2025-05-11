{config, lib, pkgs, unstable, ...}:
{
 services = {
   vaultwarden = {
     enable = true;
     package = .vaultwarden;
     
   };
 };
}
