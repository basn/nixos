{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.services.qBittorrent;
  defaultUser = "qBittorrent";
  defaultGroup = defaultUser;

  webUIAddressSubmodule = lib.types.submodule {
    options = {
      address = lib.mkOption {
        default = "127.0.0.1";
        type = lib.types.str;
        description = "The IP address to which the webui will bind.";
      };
      port = lib.mkOption {
        default = 8080;
        type = lib.types.int;
        description = "The port to which the webui will bind.";
      };
    };
  };

  # Allow configuration of the incoming port for qBittorrent
  incomingPortSubmodule = lib.types.submodule {
    options = {
      incomingPort = lib.mkOption {
        type = lib.types.int;
        default = 62876;  # Set your default incoming port here
        description = "The port to use for incoming connections.";
      };
    };
  };

  # Initialize and run the qBittorrent service with the updated configuration
  initializeAndRun = pkgs.writers.writeBash "initializeAndRun-qBittorrent-config" ''
    set -efu
    export "HOME=${cfg.dataDir}";
    mkdir -p ${cfg.configDir}

    if [ ! -f ${cfg.configDir}/qBittorrent.conf ]; then
    cat >${cfg.configDir}/qBittorrent.conf <<EOL
    [LegalNotice]
    Accepted=true

    [Network]
    Cookies=@Invalid()

    [Preferences]
    Connection\PortRangeMin=${toString cfg.incomingPort}
    Queueing\QueueingEnabled=false
    EOL
    fi

    ${cfg.package}/bin/qbittorrent-nox
  '';
in
{
  options.services.qBittorrent = {
    enable = mkEnableOption "Featureful free software BitTorrent client";

    # Web UI and incoming port options
    webUIAddress = mkOption {
      type = webUIAddressSubmodule;
      default = { };
      description = "The IP and port to which the webui will bind.";
    };

    incomingPort = mkOption {
      type = lib.types.int;
      default = 62876;
      description = "The port to use for incoming connections.";
    };

    openFirewall = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = "Expose the webui to the network.";
    };

    systemService = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to auto-launch qBittorrent as a system service.";
    };

    user = mkOption {
      type = types.str;
      default = defaultUser;
      example = "yourUser";
      description = "The user to run qBittorrent as.";
    };

    group = mkOption {
      type = types.str;
      default = defaultGroup;
      example = "yourGroup";
      description = "The group to run qBittorrent under.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/${defaultUser}";
      example = "/home/yourUser";
      description = "The path where qBittorrent config and state live.";
    };

    cacheDir = mkOption {
       type = types.path;
       default = "${cfg.dataDir}/.cache/qBittorrent";
       description = ''
         The cache directory for qBittorrent, used as XDG_CACHE_HOME.
         Useful if the default /var/empty/.cache/qBittorrent is not writable.
       '';
    };

    configDir = mkOption {
      type = types.path;
      description = "The path where the settings will exist.";
      default = cfg.dataDir + "/.config/qBittorrent";
      defaultText = literalDocBook ''
        [LegalNotice]
        Accepted=true

        [Network]
        Cookies=@Invalid()

        [Preferences]
        Connection\PortRangeMin=${toString cfg.incomingPort}
        Queueing\QueueingEnabled=false
        WebUI\Port=${cfg.webUIAddress.port}
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.qbittorrent-nox;
      defaultText = literalExpression "pkgs.qbittorrent-nox";
      description = "The qbittorrent package to use.";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts =
      mkIf cfg.openFirewall [ cfg.webUIAddress.port ];

    systemd.packages = [ cfg.package ];

    users.users = mkIf (cfg.systemService && cfg.user == defaultUser) {
      ${defaultUser} =
        {
          group = cfg.group;
          home = cfg.dataDir;
          createHome = true;
          uid = 999;
          isSystemUser = true;
          description = "qBittorrent service user";
        };
    };

    users.groups = mkIf (cfg.systemService && cfg.group == defaultGroup) {
      ${defaultGroup}.gid = 999;
    };

    systemd.services = {
      qBittorrent = mkIf cfg.systemService {
        description = "qBittorrent service";
        documentation = [ "man:qbittorrent-nox(1)" ];
        wantedBy = [ "multi-user.target" ];
        wants = [ "multi-user.target" "network-online.target" ];
        after = [ "network-online.target" "nss-lookup.target" ];
        serviceConfig = {
          Type = "exec";
          User = cfg.user;
          Group = cfg.group;
          Environment = "XDG_CACHE_HOME=${cfg.cacheDir}";
          ExecStart = initializeAndRun;
        };
      };
    };
  };
}
