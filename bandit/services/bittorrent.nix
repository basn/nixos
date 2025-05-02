# configuration.nix
{ pkgs, lib, config, unstablePkgs, ... }:
let
  seedport = 54357;
in
{
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
  systemd.services.qBittorrent.vpnConfinement = {
    enable = true;
    vpnNamespace = "wg";
  };
  services = {
    qBittorrent = {
      enable = true;
      openFirewall = false;
      webUIAddress.port = 8080;
      user = "plex";
      group = "plex";
      package = unstablePkgs.qbittorrent-nox;
      incomingPort = seedport;
      configDir = "/data2/files/qBittorrent/.config/qBittorrent/";
      dataDir = "/data2/files/qBittorrent/";
      cacheDir = "/data2/files/qBittorrent/.cache/qBittorrent";
    };
  };
}
