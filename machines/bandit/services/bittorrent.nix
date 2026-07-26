# configuration.nix
{
  config,
  lib,
  pkgs,
  unstablePkgs,
  ...
}:
let
  seedportFile = config.sops.secrets.seedport.path;
  azirePortforwardTokenFile = config.sops.secrets.azire-portforward-token.path;
  configureSeedPort = pkgs.writeShellScript "qbittorrent-configure-seedport" ''
    set -euo pipefail

    seedport="$(${pkgs.coreutils}/bin/tr -d '[:space:]"' < ${seedportFile})"
    case "$seedport" in
      ""|*[!0-9]*)
        echo "qBittorrent seed port is not numeric" >&2
        exit 1
        ;;
    esac
    if [ "$seedport" -lt 1 ] || [ "$seedport" -gt 65535 ]; then
      echo "qBittorrent seed port is outside the valid range" >&2
      exit 1
    fi

    config_file="${config.services.qbittorrent.dataDir}/qBittorrent/config/qBittorrent.conf"
    if [ ! -f "$config_file" ]; then
      echo "qBittorrent configuration is missing: $config_file" >&2
      exit 1
    fi
    ${pkgs.gnused}/bin/sed -i -E \
      "s/^Session\\\\Port=.*/Session\\\\Port=$seedport/" \
      "$config_file"

    ${pkgs.iptables}/bin/iptables -N qbittorrent-incoming 2>/dev/null || true
    ${pkgs.iptables}/bin/iptables -F qbittorrent-incoming
    ${pkgs.iptables}/bin/iptables -C INPUT -i wg0 -j qbittorrent-incoming 2>/dev/null || \
      ${pkgs.iptables}/bin/iptables -A INPUT -i wg0 -j qbittorrent-incoming
    ${pkgs.iptables}/bin/iptables -A qbittorrent-incoming -p tcp --dport "$seedport" -j ACCEPT
    ${pkgs.iptables}/bin/iptables -A qbittorrent-incoming -p udp --dport "$seedport" -j ACCEPT
  '';
  azirePortforward = pkgs.writeShellApplication {
    name = "azire-portforward";
    runtimeInputs = with pkgs; [
      curl
      gawk
      iproute2
    ];
    text = ''
      set -euo pipefail

      if [ "$(id -u)" -ne 0 ]; then
        echo "Run this command with sudo: sudo azire-portforward" >&2
        exit 1
      fi

      token="$(tr -d '[:space:]' < ${azirePortforwardTokenFile})"
      if [ -z "$token" ]; then
        echo "AzireVPN port-forwarding token is empty" >&2
        exit 1
      fi

      mapfile -t internal_ipv4s < <(
        ip netns exec wg ip -4 -o addr show dev wg0 scope global |
          awk '{ sub(/\/.*/, "", $4); print $4 }'
      )
      if [ "''${#internal_ipv4s[@]}" -ne 1 ]; then
        echo "Expected exactly one IPv4 address on wg0 in the wg namespace" >&2
        exit 1
      fi

      exec ip netns exec wg curl --fail-with-body --noproxy "*" \
        https://api.azirevpn.com/v3/portforwardings \
        -H "Authorization: Bearer $token" \
        --json "{\"internal_ipv4\": \"''${internal_ipv4s[0]}\", \"hidden\": false, \"expires_in\": 0}"
    '';
  };
in
{
  disabledModules = [ "services/torrent/qbittorrent.nix" ];
  imports = [ ./modules/qbittorrent.nix ];
  vpnNamespaces.wg = {
    enable = true;
    wireguardConfigFile = config.sops.secrets."wg".path;
    accessibleFrom = [ "192.168.0.0/24" ];
    portMappings = [
      {
        from = 8080;
        to = 8080;
      }
    ];
  };
  systemd.services.qbittorrent.vpnConfinement = {
    enable = true;
    vpnNamespace = "wg";
  };
  systemd.services.qbittorrent.serviceConfig.ExecStartPre = lib.mkAfter [ "!${configureSeedPort}" ];
  environment.systemPackages = [ azirePortforward ];
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
