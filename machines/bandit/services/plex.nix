{ unstablePkgs, ... }:

{
  services.plex = {
      enable = true;
      openFirewall = true;
      package = unstablePkgs.plex;
  };
}
