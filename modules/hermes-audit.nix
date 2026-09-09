{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.basn.hermesAudit;
  containers = builtins.attrNames config.virtualisation.oci-containers.containers;
  backend = config.virtualisation.oci-containers.backend;
  units = map (name: "${backend}-${name}.service") containers ++ cfg.units;
  health = pkgs.writeShellApplication {
    name = "hermes-runtime-health";
    runtimeInputs = [
      pkgs.systemd
      pkgs.coreutils
    ];
    text = ''
      [[ $# == 0 ]] || exit 64
      uname -n
      systemctl show --no-pager \
        --property=Id,LoadState,ActiveState,SubState,Result,ExecMainStatus,NRestarts \
        ${lib.escapeShellArgs units}
      systemctl --failed --no-legend --no-pager
      ${lib.optionalString (containers != [ ]) ''
        ${pkgs.${backend}}/bin/${backend} ps --all \
          --format '{{.Names}}\t{{.Image}}\t{{.Status}}'
      ''}
    '';
  };
  validate = pkgs.writeShellApplication {
    name = "hermes-validate-flake";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.git
      pkgs.nix
      pkgs.util-linux
    ];
    text = builtins.readFile ./hermes-validate-flake.sh;
  };
  candidate = pkgs.writeShellApplication {
    name = "hermes-candidate-flake";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.git
      pkgs.nix
      pkgs.python3
    ];
    text = ''
      exec python3 ${./hermes-candidate-flake.py} "$@"
    '';
  };
  dispatch = pkgs.writeShellApplication {
    name = "hermes-audit-dispatch";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      # SSH_ORIGINAL_COMMAND is data, never shell code.
      case "''${SSH_ORIGINAL_COMMAND:-}" in
        health)
          exec /run/wrappers/bin/sudo -n ${health}/bin/hermes-runtime-health
          ;;
        ${lib.optionalString cfg.validation ''
          validate\ *)
            revision="''${SSH_ORIGINAL_COMMAND#validate }"
            [[ "$revision" =~ ^[0-9a-f]{40}$ ]] || exit 64
            exec timeout --kill-after=30s 30m ${validate}/bin/hermes-validate-flake "$revision"
            ;;
          candidate\ *)
            revision="''${SSH_ORIGINAL_COMMAND#candidate }"
            [[ "$revision" =~ ^[0-9a-f]{40}$ ]] || exit 64
            exec timeout --kill-after=30s 90m ${candidate}/bin/hermes-candidate-flake "$revision"
            ;;
        ''}
        *) echo 'Allowed: health${lib.optionalString cfg.validation " or validate|candidate <current-main-commit>"}' >&2; exit 64 ;;
      esac
    '';
  };
in
{
  options.basn.hermesAudit = {
    enable = lib.mkEnableOption "restricted Hermes runtime inspection";
    validation = lib.mkEnableOption "validation and candidate-update analysis of current basn/nixos main";
    units = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };
  config = lib.mkIf cfg.enable {
    users.groups.hermes-audit = { };
    users.users.hermes-audit = {
      isSystemUser = true;
      group = "hermes-audit";
      home = "/var/lib/hermes-audit";
      createHome = true;
      homeMode = "0700";
      shell = pkgs.bash;
      openssh.authorizedKeys.keys = [
        ''restrict,from="10.1.1.10,100.86.207.157,172.17.0.0/16",command="${dispatch}/bin/hermes-audit-dispatch" ${lib.removeSuffix "\n" (builtins.readFile ./hermes-audit-key.pub)}''
      ];
    };
    services.openssh.extraConfig = ''
      Match User hermes-audit
        AuthenticationMethods publickey
        PasswordAuthentication no
        KbdInteractiveAuthentication no
        DisableForwarding yes
        PermitTTY no
        PermitUserRC no
        ForceCommand ${dispatch}/bin/hermes-audit-dispatch
      Match all
    '';
    security.sudo.extraRules = [
      {
        users = [ "hermes-audit" ];
        commands = [
          {
            command = "${health}/bin/hermes-runtime-health";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
