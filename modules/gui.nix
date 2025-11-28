{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.basn;
in
{
  options = {
    userGraphicalModule.enableForGraphical = mkOption {
      type = types.bool;
      default = false;
      description = "Enable user-specific settings only if graphical session is running.";
    };
  config = lib.mkIf cfg.enableForGraphical {
      users.users.basn.packages = [ whois asn gh nixpkgs-review ];
    };
  };
}
    

