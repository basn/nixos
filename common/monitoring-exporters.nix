{ config, lib, ... }:
{
  config = lib.mkIf config.services.netbird.enable {
    services.prometheus.exporters = {
      node = {
        enable = true;
        listenAddress = "0.0.0.0";
        enabledCollectors = [
          "systemd"
          "processes"
        ];
      };
      smartctl = {
        enable = true;
        listenAddress = "0.0.0.0";
        maxInterval = "5m";
      };
    };

    networking.firewall.extraInputRules = ''
      iifname "wt0" ip saddr 100.86.89.177 tcp dport { 9100, 9633 } accept
    '';
  };
}
