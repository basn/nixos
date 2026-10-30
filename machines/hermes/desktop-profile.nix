{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.hermes-agent;
  home = "${cfg.stateDir}/.hermes";
  profile = "${home}/profiles/desktop";
  common = import "${inputs.hermes-agent}/nix/moduleCommon.nix" { inherit lib; };
  configFiles = common.mkConfigFiles {
    inherit pkgs;
    workingDirectory = "/workspace";
    cfg = cfg // {
      configFile = null;
      # Share policy/model declarations, not the audit profile's tools, mounts,
      # plugins, messaging adapters, or injected environment.
      settings =
        lib.getAttrs [
          "model"
          "fallback_providers"
          "auxiliary"
          "timezone"
          "approvals"
          "security"
          "compression"
        ] cfg.settings
        // {
          gateway.standalone = false;
          terminal = {
            backend = "docker";
            cwd = "/workspace";
            timeout = 180;
            docker_image = "nousresearch/hermes-sandbox:desktop";
            docker_shared_container_key = "desktop-v1";
            docker_mount_cwd_to_workspace = false;
            docker_volumes = [ "${profile}/workspace:/workspace" ];
            docker_extra_args = [
              "--dns=10.1.1.8"
              "--dns-search=."
            ];
            docker_forward_env = [ ];
            env_passthrough = [ ];
            client_env_passthrough = [ ];
            credential_files = [ ];
            container_cpu = 2;
            container_memory = 6144;
            container_disk = 61440;
            container_persistent = true;
            docker_persist_across_processes = true;
            docker_orphan_reaper = true;
          };
          toolsets = [
            "terminal"
            "file"
            "browser"
            "computer_use"
            "memory"
            "session_search"
            "clarify"
          ];
          browser = {
            engine = "chrome";
            headed = true;
            auto_local_for_private_urls = false;
          };
          bot_desktop.placement = "terminal";
        };
    };
  };
  python = pkgs.python3.withPackages (p: [ p.pyyaml ]);
in
{
  # Host-local bridge until the upstream single-profile Nix module supports
  # named profiles. Revisit this provisioning when updating the Hermes input.
  system.activationScripts.hermes-desktop-profile = lib.stringAfter [ "hermes-agent-setup" ] ''
    ${pkgs.util-linux}/bin/runuser -u ${lib.escapeShellArg cfg.user} -- \
      ${python}/bin/python3 ${./provision-desktop-profile.py} \
      ${lib.escapeShellArg home} ${configFiles.generated}
  '';
}
