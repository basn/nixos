{ config, lib, ... }:
let
  cfg = config.basn.remoteSyslog;
in
{
  options.basn.remoteSyslog = {
    enable = lib.mkEnableOption "forward host logs to a central syslog server";
    target = lib.mkOption {
      type = lib.types.str;
      default = "logger";
      description = "Hostname or IP of the remote syslog collector.";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 1514;
      description = "Remote syslog listener port.";
    };
    protocol = lib.mkOption {
      type = lib.types.enum [
        "tcp"
        "udp"
      ];
      default = "tcp";
      description = "Protocol used for forwarding logs.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.rsyslogd = {
      enable = true;
      extraConfig = ''
        *.* action(
          type="omfwd"
          target="${cfg.target}"
          port="${toString cfg.port}"
          protocol="${cfg.protocol}"
          action.resumeRetryCount="-1"
          queue.type="linkedList"
          queue.size="10000"
        )
      '';
    };
  };
}
