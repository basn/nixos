{ unstablePkgs,  ...}:
{
 services = {
   unifi = {
     enable = true;
     unifiPackage = unstablePkgs.unifi;
     mongodbPackage = unstablePkgs.mongodb;
     openFirewall = true;
   };
 };
}
