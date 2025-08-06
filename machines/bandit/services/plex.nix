{ unstablePkgs, ... }:

{
  services.plex = {
      enable = true;
      openFirewall = true;
      package = unstablePkgs.plex;
  };
  users.users.plex.extraGroups = [ "video" ];
}
