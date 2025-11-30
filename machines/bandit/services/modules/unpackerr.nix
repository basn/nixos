{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.unpackerr;
in
{
  options.services.unpackerr = {
    enable = lib.mkEnableOption "unpackerr";
    package = lib.mkPackageOption pkgs "unpackerr" { };

    user = lib.mkOption {
      type = lib.types.str;
      default = "unpackerr";
      description = lib.mdDoc "User account under which unpackerr runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "unpackerr";
      description = lib.mdDoc "Group under which unpackerr runs.";
    };

    settings = lib.mkOption {
      default = { };
      description = "unpackerr config file";
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Useful for storing api keys like: UN_SONARR_0_API_KEY, UN_RADARR_0_API_KEY";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      services.unpackerr = {
        enable = true;
        description = "Runs unpackerr in daemon mode";
        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          ProtectHome = "yes";
          DeviceAllow = [ "" ];
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          PrivateDevices = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          ProtectProc = "invisible";
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = "native";
          PrivateUsers = true;
          ExecStart = "${lib.getExe cfg.package} -c ${
            (pkgs.formats.toml { }).generate "config.toml" cfg.settings
          }";
          EnvironmentFile = cfg.environmentFile;
        };

        wantedBy = [ "default.target" ];
      };
    };
  };
}
