"""Offline tests against an existing locked Hermes checkout; no Nix or live agents.

Usage: python3 -B machines/hermes/test-team-plugin.py /path/to/hermes-agent
Only Codex credential lookup is mocked; discovery, schema and route resolution are real.
The small Nix member declarations are read statically, not evaluated as a NixOS module.
"""

import copy
import json
import os
from pathlib import Path
import re
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

import yaml

SOURCE = Path(sys.argv.pop(1)).resolve()
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(SOURCE))

from agent.delegation_provider import DelegationRouteError
from agent.agent_init_fallback import _fallback_entries
from agent.delegation_registry import get_active_provider
from hermes_cli import plugins, runtime_provider
from tools import delegate_tool as dt
from tools.delegate_tool_config import _resolve_child_runtime, _resolve_child_credential_pool
from tools.delegate_tool_routes import resolve_task_routes, schema_extension
from tools.delegate_tool_toolsets import DELEGATE_BLOCKED_TOOLS, _resolve_child_toolsets


def declared_members():
    text = (HERE / "configuration.nix").read_text()
    members = {}
    for name in ("monica", "jared"):
        block = re.search(rf"            {name} = \{{(.*?)\n            \}};", text, re.S)
        assert block, f"Missing declaration for {name}"
        members[name] = {
            key: [] if value.startswith("[") else json.loads(value)
            for key, value in re.findall(r'(\w+) = ("[^"\n]*"|\[\s*\]);', block[1])
        }
    return members


class TeamTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory(prefix="hermes-team-")
        cls.addClassCleanup(cls.tmp.cleanup)
        home = Path(cls.tmp.name)
        (home / "plugins").mkdir()
        (home / "plugins" / "nix-managed-team-plugin").symlink_to(HERE / "team-plugin")
        cls.config = {
            "backend": "silicon-valley-team",
            "backends": {"silicon-valley-team": {"members": declared_members()}},
            "max_concurrent_children": 2,
            "max_spawn_depth": 1,
            "orchestrator_enabled": True,
        }
        (home / "config.yaml").write_text(yaml.safe_dump({
            "plugins": {"enabled": ["silicon-valley-team"]},
            "delegation": cls.config,
        }))
        env = patch.dict(os.environ, {"HOME": str(home), "HERMES_HOME": str(home)})
        env.start()
        cls.addClassCleanup(env.stop)
        bundled = home / "bundled"
        bundled.mkdir()
        (bundled / "delegation").symlink_to(SOURCE / "plugins" / "delegation")
        paths = patch.object(plugins, "get_bundled_plugins_dir", return_value=bundled)
        paths.start()
        cls.addClassCleanup(paths.stop)
        cls.manager = plugins.PluginManager()
        cls.addClassCleanup(cls.manager.unload)
        cls.manager.discover_and_load()
        cls.provider = get_active_provider(cls.config)

    def parent(self):
        return SimpleNamespace(
            model="gpt-6-astra", provider="openai-codex", base_url="https://parent.invalid/v1",
            api_key="synthetic-parent-key", api_mode="codex_responses", request_overrides={},
            _credential_pool=object(), _fallback_chain=[{
                "provider": "openai-codex", "model": "gpt-6.1-sol",
            }], enabled_toolsets=["terminal", "file", "web", "cronjob"],
        )

    def test_registration_schema_and_guidance(self):
        from tools.registry import registry
        definition = registry.get_definitions({"delegate_task"})[0]["function"]
        schema = definition["parameters"]["properties"]["tasks"]["items"]["properties"]
        self.assertEqual(schema["teammate"]["enum"], ["jared", "monica"])
        self.assertIn("Richard handles approved schedule changes", definition["description"])
        for guidance in (definition["description"], schema["teammate"]["description"]):
            self.assertIn("writes docs, records decisions, checks docs against changes", guidance)
            self.assertIn("documentation", guidance.lower())
            self.assertNotIn("implementation", guidance.lower())
        self.assertEqual(schema_extension(self.config), schema_extension(copy.deepcopy(self.config)))

    def test_unnamed_is_exact_pass_through(self):
        config = {**self.config, "model": "override", "request_overrides": {"x": 1},
                  "fallback_providers": [], "reasoning_effort": "high"}
        before = copy.deepcopy(config)
        self.assertEqual(self.provider.route_task({"goal": "ordinary task"}, config), config)
        self.assertEqual(config, before)
        routes, error = resolve_task_routes([{"goal": "ordinary task"}], self.config, self.parent())
        self.assertIsNone(error)
        self.assertIsNone(routes[0].creds["provider"])
        self.assertIsNone(routes[0].creds["model"])

    def test_invalid_names_refused(self):
        for name in ("richard", "Monica", "unknown", "", [], 3):
            with self.subTest(name=name):
                with self.assertRaises(DelegationRouteError):
                    self.provider.route_task({"teammate": name}, self.config)
                routes, error = resolve_task_routes([{"teammate": name}], self.config, self.parent())
                self.assertIsNone(error)
                self.assertTrue(routes[0].error)
                self.assertEqual(routes[0].creds, {})

    def test_monica_explicit_codex(self):
        with patch.object(runtime_provider, "resolve_runtime_provider", return_value={
            "provider": "openai-codex", "base_url": "https://codex.invalid/v1",
            "api_key": "synthetic-codex-key", "api_mode": "codex_responses",
        }) as resolve:
            routes, error = resolve_task_routes([{"teammate": "monica"}], self.config, self.parent())
        self.assertIsNone(error)
        self.assertIsNone(routes[0].error)
        resolve.assert_called_once_with(requested="openai-codex", target_model="gpt-6.1-sol")
        self.assertEqual(routes[0].creds["model"], "gpt-6.1-sol")
        self.assertEqual(routes[0].creds["provider"], "openai-codex")
        self.assertEqual(routes[0].label, "Monica")

    def test_jared_direct_dummy_key_no_fallback(self):
        config = {**self.config, "fallback_providers": self.parent()._fallback_chain}
        with patch.object(runtime_provider, "resolve_runtime_provider", side_effect=AssertionError("cloud lookup")):
            routes, error = resolve_task_routes([{"teammate": "jared"}], config, self.parent())
        self.assertIsNone(error)
        route = routes[0]
        self.assertIsNone(route.error)
        self.assertEqual(route.label, "Jared")
        creds = route.creds
        self.assertEqual(creds["provider"], "custom")
        self.assertEqual(creds["base_url"], "http://bandit.netbird.basn.se:8080/v1")
        self.assertEqual(creds["api_key"], "no-key-required")
        self.assertEqual(creds["model"], "gemma-4-12b-local")
        self.assertEqual(creds["api_mode"], "chat_completions")
        runtime = _resolve_child_runtime(
            self.parent(), config, "synthetic-parent-key", model=creds["model"],
            override_provider=creds["provider"], override_base_url=creds["base_url"],
            override_api_key=creds["api_key"], override_api_mode=creds["api_mode"],
            override_acp_command=None, override_acp_args=None, routing_cfg=route.routing_cfg,
        )
        self.assertEqual(runtime["api_key"], "no-key-required")
        self.assertEqual(route.routing_cfg["fallback_providers"], [])
        self.assertIsNone(runtime["fallback_model"])
        self.assertEqual(_fallback_entries(runtime["fallback_model"]), [])
        # No custom provider registration: the child's fixed dummy key keeps ownership.
        self.assertIsNone(_resolve_child_credential_pool("custom", self.parent(), creds["base_url"]))
        self.assertNotIn("api_key", route.report())

    def test_core_blocks_child_scheduling(self):
        self.assertIn("cronjob_manage", DELEGATE_BLOCKED_TOOLS)
        for role in ("leaf", "orchestrator"):
            enabled, disabled = _resolve_child_toolsets(self.parent(), None, role)
            self.assertNotIn("cronjob", enabled)
            self.assertIn("cronjob", disabled)


if __name__ == "__main__":
    unittest.main()
