"""Repository-only checks; no secrets are decrypted and no live API is called."""

import json
from pathlib import Path
import subprocess


root = Path(__file__).resolve().parents[1]
oc = json.loads((root / "hjem/configs/opencode.json").read_text())
provider = oc["providers"]["hermes"]
assert provider["env"] == ["HERMES_API_KEY"]
assert provider["package"] == "@opencode/ai/providers/openai-compatible"
assert provider["settings"] == {"baseURL": "https://api.hermes.basn.se/v1"}
assert provider["models"]["hermes-agent"]["capabilities"] == {
    "tools": False, "input": ["text"], "output": ["text"]
}
agent = oc["agents"]["hermes"]
assert agent["mode"] == "subagent"
assert agent["model"] == "hermes/hermes-agent"
assert agent["permissions"] == [{"action": "*", "resource": "*", "effect": "deny"}]
astra = oc["agent"]["astra-orchestrator"]
assert astra["permission"]["task"] == {
    "*": "deny", "sol-coder": "allow", "explore": "allow", "hermes": "allow"
}
assert astra["permission"]["edit"] == astra["permission"]["bash"] == "deny"
assert oc["agent"]["sol-coder"]["permission"]["task"] == "deny"

expression = r'''
let
  f = builtins.getFlake (toString ./.);
  h = f.nixosConfigurations.hermes.config;
  s = f.nixosConfigurations.services.config;
  b = f.nixosConfigurations.battlestation.config;
  v = s.services.nginx.virtualHosts."api.hermes.basn.se";
in {
  api = h.services.hermes-agent.settings.platforms.api_server;
  approvals = h.services.hermes-agent.settings.approvals;
  firewall = h.networking.firewall.extraInputRules;
  ports = h.networking.firewall.allowedTCPPorts;
  apiVhost = {
    inherit (v) enableACME forceSSL;
    locations = builtins.mapAttrs (name: location:
      if name == "/" then { inherit (location) return; }
      else { inherit (location) proxyPass extraConfig; }
    ) v.locations;
  };
  dashboardUpstream = s.services.nginx.virtualHosts."hermes.basn.se".locations."/".proxyPass;
  dns = s.services.blocky.settings.customDNS.mapping."api.hermes.basn.se";
  hermesEnv = h.systemd.services.hermes-agent.serviceConfig.EnvironmentFile;
  hermesSecret = { inherit (h.sops.secrets.hermes-env) mode path; };
  clientSecret = { inherit (b.sops.secrets.opencode-mcp-env) mode; };
}
'''
cfg = json.loads(subprocess.check_output(
    ["nix", "eval", "--json", "--impure", "--no-update-lock-file", "--expr", expression],
    cwd=root,
))
assert cfg["api"] == {"enabled": True, "extra": {
    "host": "10.1.1.10", "port": 8642, "model_name": "hermes-agent",
    "tool_progress_events": False,
}}
assert cfg["approvals"]["mode"] == "manual"
assert cfg["approvals"]["unattended_mode"] == "deny"
assert "ip saddr 10.1.1.8 tcp dport 8642 accept" in cfg["firewall"]
assert 8642 not in cfg["ports"]
vhost = cfg["apiVhost"]
assert vhost["enableACME"] and vhost["forceSSL"]
assert set(vhost["locations"]) == {"/", "= /v1/models", "= /v1/chat/completions"}
assert vhost["locations"]["/"]["return"] == "404"
for route in ("= /v1/models", "= /v1/chat/completions"):
    location = vhost["locations"][route]
    assert location["proxyPass"] == "http://10.1.1.10:8642"
    assert "proxy_set_header Authorization $http_authorization;" in location["extraConfig"]
    assert "auth_request" not in location["extraConfig"]
chat = vhost["locations"]["= /v1/chat/completions"]["extraConfig"]
for setting in ("proxy_buffering off;", "proxy_read_timeout 3600s;", "proxy_send_timeout 3600s;"):
    assert setting in chat
assert cfg["dashboardUpstream"] == "http://10.1.1.10:9119"
assert cfg["dns"] == "10.1.1.8"
assert cfg["hermesSecret"]["mode"] == cfg["clientSecret"]["mode"] == "0400"
assert cfg["hermesEnv"] == cfg["hermesSecret"]["path"]
print("Hermes API wiring, permissions and narrow evaluated Nix checks passed")
