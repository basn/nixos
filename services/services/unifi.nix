{config, lib, pkgs, unstable, ...}:
let
  unstablePkgs = import <unstable> { config = { allowUnfree = true; }; };
in
{
 services = {
   unifi = {
     enable = true;
     unifiPackage = unstablePkgs.unifi;
     mongodbPackage = unstablePkgs.mongodb;
   };
 };
}
