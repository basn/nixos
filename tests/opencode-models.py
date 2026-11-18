"""Offline model declaration checks; no Nix evaluation or provider requests."""

import json
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parent.parent


class ModelTests(unittest.TestCase):
    def test_opencode_roles_and_custom_models(self):
        config = json.loads((ROOT / "hjem/configs/opencode.json").read_text())
        self.assertEqual(config["agent"]["astra-orchestrator"]["model"], "openai/gpt-6.2-astra")
        self.assertEqual(config["agents"]["sol-coder"]["model"], "openai/gpt-6.2-sol")
        for model in ("gpt-6.2-astra", "gpt-6.2-sol"):
            self.assertEqual(config["providers"]["openai"]["models"][model]["modelID"], model)
        self.assertEqual(config["model"], "openai/gpt-6.1-terra")
        self.assertEqual(config["small_model"], "openai/gpt-6-luna")

    def test_no_stale_astra_sol_declarations(self):
        for path in ("hjem/configs/opencode.json", "machines/hermes/configuration.nix",
                     "machines/hermes/test-team-plugin.py"):
            with self.subTest(path=path):
                text = (ROOT / path).read_text()
                self.assertNotIn('"gpt-6-astra"', text)
                self.assertNotIn('"gpt-6.1-sol"', text)
                self.assertNotIn('"openai/gpt-6-astra"', text)
                self.assertNotIn('"openai/gpt-6.1-sol"', text)


if __name__ == "__main__":
    unittest.main()
