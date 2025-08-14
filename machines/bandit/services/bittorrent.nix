# configuration.nix
{ pkgs, lib, config, unstablePkgs, ... }:
let
  seedport = 53090;
in
{
  disabledModules = [ "services/torrent/qbittorrent.nix" ];
  imports = [
    ./modules/qbittorrent.nix
  ];
  vpnNamespaces.wg = {
    enable = true;
    wireguardConfigFile = config.sops.secrets."wg".path;
    accessibleFrom = [
      "192.168.0.0/24"
    ];
    portMappings = [
      { from = 8080; to = 8080; }
    ];
    openVPNPorts = [{
      port = seedport;
      protocol = "both";
    }];
  };
  systemd.services.qbittorrent.vpnConfinement = {
    enable = true;
    vpnNamespace = "wg";
  };
  services = {
    qbittorrent = {
      enable = true;
      openFirewall = false;
      port = 8080;
      user = "plex";
      group = "plex";
      package = unstablePkgs.qbittorrent-nox;
      dataDir = "/data2/files/qBittorrent/";
    };
  };
}
