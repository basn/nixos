{ pkgs, ... }:
let
  opencodeSkillNew = pkgs.writeShellScriptBin "opencode-skill-new" ''
    set -eu
    if [ "$#" -ne 1 ]; then
      echo "Usage: opencode-skill-new <skill-name>" >&2
      exit 1
    fi
    name="$1"
    base="$HOME/.config/opencode/skills/$name"
    mkdir -p "$base"
    file="$base/SKILL.md"
    if [ ! -f "$file" ]; then
      cat >"$file" <<EOF
# $name

## Purpose
Describe what this skill is for.

## Usage
Document how to trigger and use it.
EOF
    fi
    echo "$file"
  '';

  opencodeMcpNew = pkgs.writeShellScriptBin "opencode-mcp-new" ''
    set -eu
    if [ "$#" -lt 2 ]; then
      echo "Usage: opencode-mcp-new <server-name> <command...>" >&2
      exit 1
    fi
    name="$1"
    shift
    mkdir -p "$HOME/.config/opencode/mcp.d"
    out="$HOME/.config/opencode/mcp.d/$name.json"
    cmd_json="$(printf '%s\n' "$@" | ${pkgs.jq}/bin/jq -R . | ${pkgs.jq}/bin/jq -s .)"
    ${pkgs.jq}/bin/jq -n \
      --arg name "$name" \
      --argjson cmd "$cmd_json" \
      '{mcp:{($name):{type:"local",enabled:true,command:$cmd}}}' >"$out"
    echo "$out"
  '';

  opencodeMcpSync = pkgs.writeShellScriptBin "opencode-mcp-sync" ''
    set -eu
    cfg="$HOME/.config/opencode/opencode.json"
    dir="$HOME/.config/opencode/mcp.d"
    mkdir -p "$HOME/.config/opencode" "$dir"
    if [ ! -f "$cfg" ]; then
      cat >"$cfg" <<EOF
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {}
}
EOF
    fi
    tmp="$(mktemp)"
    if ls "$dir"/*.json >/dev/null 2>&1; then
      ${pkgs.jq}/bin/jq -s '
        .[0] as $base
        | (reduce .[1:][] as $f ({}; . * ($f.mcp // {}))) as $overlay
        | $base * {mcp: (($base.mcp // {}) * $overlay)}
      ' "$cfg" "$dir"/*.json >"$tmp"
      mv "$tmp" "$cfg"
      echo "$cfg"
    else
      echo "No MCP fragment files found in $dir" >&2
    fi
  '';
in
{
  systemd.tmpfiles.rules = [
    "d /home/basn/.config/opencode 0755 basn users - -"
    "d /home/basn/.config/opencode/skills 0755 basn users - -"
    "d /home/basn/.config/opencode/mcp.d 0755 basn users - -"
  ];

  environment.systemPackages = with pkgs; [
    opencode
    jq
    opencodeSkillNew
    opencodeMcpNew
    opencodeMcpSync
  ];

  environment.shellAliases = {
    oc = "opencode";
    ocfg = "nvim ~/.config/opencode/opencode.json";
    oskills = "ls ~/.config/opencode/skills";
    omcps = "ls ~/.config/opencode/mcp.d";
  };
}
