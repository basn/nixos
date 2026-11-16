"""Offline config regression checks; not OpenCode's scanner or approval runtime."""

import json
from pathlib import Path


root = Path(__file__).resolve().parents[1]
config = json.loads((root / "hjem/configs/opencode.json").read_text())
cli = json.loads((root / "hjem/configs/opencode-cli.json").read_text())
sol = config["agents"]["sol-coder"]
assert "sol-coder" not in config["agent"]
assert "permission" not in sol
assert "permission" not in config
assert "permissions" not in config
for agents in (config["agent"], config["agents"]):
    for name, agent in agents.items():
        if name != "hermes":
            assert "permission" not in agent, name
            assert "permissions" not in agent, name
assert sol["model"] == "openai/gpt-6.1-sol"
assert sol["mode"] == "subagent"
assert config["formatter"] is True
assert config["agents"]["hermes"]["permissions"] == [
    {"action": "*", "resource": "*", "effect": "deny"}
]


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
print("OpenCode JSON, local permission defaults, Hermes policy, CLI preferences and Hjem mapping passed")
