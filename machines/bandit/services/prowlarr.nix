{ unstablePkgs, inputs, ... }:
let
  prowlarrModule = import "${inputs.nixpkgs-unstable.outPath}/nixos/modules/services/misc/servarr/prowlarr.nix";
in
{
  disabledModules = [ "services/misc/servarr/prowlarr.nix" ];
  imports = [ prowlarrModule ];
  services = {
    prowlarr = {
      enable = true;
      openFirewall = true;
      package = unstablePkgs.prowlarr;
      dataDir = "/data2/files/prowlarr/";
    };
  };
}
