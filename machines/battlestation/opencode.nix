{ config, pkgs, ... }:
let
  opencodeSkillNew = pkgs.writeShellScriptBin "opencode-skill-new" ''
        set -eu
        if [ "$#" -ne 1 ]; then
          echo "Usage: opencode-skill-new <skill-name>" >&2
          exit 1
        fi
        name="$1"
        if ! printf '%s' "$name" | ${pkgs.gnugrep}/bin/grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' || [ "''${#name}" -gt 64 ]; then
          echo "Skill name must be lowercase hyphen-separated and at most 64 characters" >&2
          exit 1
        fi
        base="$HOME/.config/opencode/skills/$name"
        mkdir -p "$base"
        file="$base/SKILL.md"
        if [ ! -f "$file" ]; then
          cat >"$file" <<EOF
    ---
    name: $name
    description: Describe what this skill does and when to use it.
    ---

    # $name

    ## Purpose
    Describe what this skill is for.

    ## Usage
    Document how to trigger and use it.
    EOF
        fi
        echo "$file"
  '';

  opencodeWorkflow = pkgs.writeShellApplication {
    name = "opencode-workflow";
    runtimeInputs = [
      pkgs.git
      pkgs.python3
    ];
    text = ''
      exec ${pkgs.python3}/bin/python3 ${../../scripts/opencode-workflow.py} --opencode ${pkgs.opencode}/bin/opencode "$@"
    '';
  };

  opencodeWithMcpEnv = pkgs.writeShellScriptBin "oc" ''
    set -a
    . ${config.sops.secrets.opencode-mcp-env.path}
    set +a
    exec ${pkgs.opencode}/bin/opencode "$@"
  '';
in
{
  sops = {
    defaultSopsFile = ./secrets/opencode-mcp.env;
    secrets.opencode-mcp-env = {
      format = "dotenv";
      owner = "basn";
      group = "users";
      mode = "0400";
    };
  };

  systemd.tmpfiles.rules = [
    "d /home/basn/.config/opencode 0755 basn users - -"
    "d /home/basn/.config/opencode/skills 0755 basn users - -"
  ];

  environment.systemPackages = with pkgs; [
    pkgs.opencode
    nixd
    opencodeSkillNew
    opencodeWorkflow
    opencodeWithMcpEnv
  ];

  environment.shellAliases = {
    ocfg = "nvim /home/basn/nixos/hjem/configs/opencode.json";
    oskills = "ls ~/.config/opencode/skills";
  };
}
