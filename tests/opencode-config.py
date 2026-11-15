"""Offline config regression checks; not OpenCode's scanner or approval runtime."""

import json
from pathlib import Path
import re


root = Path(__file__).resolve().parents[1]
config = json.loads((root / "hjem/configs/opencode.json").read_text())
cli = json.loads((root / "hjem/configs/opencode-cli.json").read_text())
sol = config["agents"]["sol-coder"]
assert "sol-coder" not in config["agent"]
assert "permission" not in sol
assert sol["model"] == "openai/gpt-6.1-sol"
assert sol["mode"] == "subagent"
assert config["formatter"] is True
assert config["agents"]["hermes"]["permissions"] == [
    {"action": "*", "resource": "*", "effect": "deny"}
]


def matches(pattern, value):
    # V2 whole-value wildcards, not fnmatch's extra bracket syntax.
    regex = re.escape(pattern).replace(r"\*", ".*").replace(r"\?", ".")
    return re.fullmatch(regex, value) is not None


def effect(action, resource):
    result = "ask"
    for rule in sol["permissions"]:
        if matches(rule["action"], action) and matches(rule["resource"], resource):
            result = rule["effect"]
    return result


safe = {
    "pwd",
    "git status --short",
    "git status --porcelain=v1",
    "git --no-pager diff --no-ext-diff --no-textconv",
    "git --no-pager diff --no-ext-diff --no-textconv --cached",
    "git --no-pager diff --no-ext-diff --no-textconv --check",
    "nixfmt --check hjem/tooling.nix",
}
assert {r["resource"] for r in sol["permissions"]
        if r["action"] == "shell" and r["effect"] == "allow"} == safe
for command in safe:
    assert effect("shell", command) == "allow", command
    for suffix in (" --help", "; touch /tmp/changed", " && nix build .#laptop",
                   " | sh", " > /tmp/changed", " $(touch /tmp/changed)"):
        assert effect("shell", command + suffix) == "ask", command + suffix
for command in (
    "git diff", "git diff --ext-diff", "git diff --textconv",
    "git status --short --upload-pack=evil", "git push", "git reset --hard",
    "nix build .#laptop", "nix flake check --no-build", "nix eval .#laptop",
    "nix shell nixpkgs#nixfmt", "nixfmt hjem/tooling.nix",
    "nixfmt --check --output /tmp/changed hjem/tooling.nix",
    "bash -c pwd", "python3 -c 'print(1)'", "ssh host pwd", "sudo pwd",
    "find . -exec rm {} +", "rm file",
):
    assert effect("shell", command) == "ask", command
for action in ("read", "glob", "grep", "list", "edit"):
    assert effect(action, "example") == "allow"
assert effect("external_directory", "/nix/store/example/*") == "allow"
assert effect("external_directory", "/other/*") == "ask"
for action in ("subagent", "homeassistant_call_service", "unifi_update", "drawio_edit"):
    assert effect(action, "*") == "deny"
assert cli == {
    "$schema": "https://opencode.ai/v2/cli.json",
    "theme": {"name": "github", "mode": "dark"},
    "diffs": {"wrap": "word", "view": "unified"},
    "session": {"sidebar": "auto", "scrollbar": False, "thinking": "show"},
    "animations": True,
}
assert '".config/opencode/cli.json".source = ./configs/opencode-cli.json;' in (
    root / "hjem/tooling.nix"
).read_text()
print("OpenCode JSON, ordered policy, CLI preferences and Hjem mapping passed")
