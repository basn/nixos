"""Mocked tests for the local OpenCode workflow gate; no model is contacted."""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("opencode_workflow", ROOT / "scripts/opencode-workflow.py")
assert SPEC and SPEC.loader
WORKFLOW = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(WORKFLOW)


FAKE_OPENCODE = '''#!/usr/bin/env python3
import json
from pathlib import Path
import re
import sys

agent = sys.argv[sys.argv.index("--agent") + 1]
workspace = Path(sys.argv[sys.argv.index("--dir") + 1])
prompt = sys.argv[-1]
mode = (Path(__file__).with_name("mode").read_text().strip())
if agent == "sol-coder":
    (workspace / "coder-ran").write_text("yes")
    print('{"verdict":"PASS"}')
    raise SystemExit(0)
snapshot = re.search(r"Reviewed immutable snapshot: ([0-9a-f]+)", prompt).group(1)
if mode == "malformed":
    print("not json")
elif mode == "absent":
    pass
elif mode == "fail":
    print(json.dumps({"verdict":"FAIL","snapshot":snapshot,"findings":["missing"],"verification":[],"skipped":[]}))
elif mode == "blocked":
    print(json.dumps({"verdict":"BLOCKED","snapshot":snapshot,"findings":["tool unavailable"],"verification":[],"skipped":[]}))
elif mode == "stale":
    print(json.dumps({"verdict":"PASS","snapshot":"0" * 64,"findings":[],"verification":[],"skipped":[]}))
elif mode == "mutate":
    (workspace / "qa-mutated").write_text("bad")
    print(json.dumps({"verdict":"PASS","snapshot":snapshot,"findings":[],"verification":[],"skipped":[]}))
else:
    print(json.dumps({"verdict":"PASS","snapshot":snapshot,"findings":[],"verification":[{"command":"test -f coder-ran","result":"PASS"}],"skipped":[]}))
'''


class WorkflowGateTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.repo = Path(self.temp.name) / "repo"
        self.repo.mkdir()
        self.git("init")
        self.git("config", "user.email", "test@example.invalid")
        self.git("config", "user.name", "Test")
        (self.repo / "README.md").write_text("test\n")
        self.git("add", "README.md")
        self.git("commit", "-m", "initial")
        self.config = self.repo / "opencode.json"
        self.config.write_text(json.dumps({"agent": {}}))
        self.fake = Path(self.temp.name) / "fake-opencode"
        self.fake.write_text(FAKE_OPENCODE)
        self.fake.chmod(0o755)
        self.mode = Path(self.temp.name) / "mode"
        self.mode.write_text("pass")
        self.task = self.repo / "task.md"
        self.task.write_text("Scope: tests.\nAcceptance: coder marker exists.\n")

    def tearDown(self) -> None:
        self.temp.cleanup()

    def git(self, *args: str) -> None:
        subprocess.run(["git", *args], cwd=self.repo, check=True, capture_output=True)

    def invoke(self, *, mode: str = "pass", checks: list[str] | None = None, repairs: int = 0) -> int:
        self.mode.write_text(mode)
        argv = [
            "--repo", str(self.repo),
            "--config", str(self.config),
            "--opencode", str(self.fake),
            "run", "--task", str(self.task), "--max-repairs", str(repairs),
        ]
        for check in checks if checks is not None else ["test -f coder-ran"]:
            argv.extend(["--check", check])
        return WORKFLOW.main(argv)

    def test_valid_qa_and_checks_permit_ready(self) -> None:
        self.assertEqual(self.invoke(), 0)

    def test_missing_malformed_fail_or_blocked_qa_never_permit_ready(self) -> None:
        for mode in ("absent", "malformed", "fail", "blocked", "stale"):
            with self.subTest(mode=mode):
                self.assertEqual(self.invoke(mode=mode), 2)

    def test_declarative_default_and_delegation_permissions(self) -> None:
        config = json.loads((ROOT / "hjem/configs/opencode.json").read_text())
        self.assertEqual(config["default_agent"], "astra-orchestrator")
        coordinator = config["agent"]["astra-orchestrator"]["permission"]
        self.assertEqual(coordinator["task"]["sol-coder"], "allow")
        self.assertEqual(coordinator["task"]["astra-qa"], "allow")
        self.assertEqual(coordinator["task"]["explore"], "allow")
        self.assertEqual(config["agent"]["sol-coder"]["permission"]["task"], "deny")
        self.assertEqual(config["agent"]["astra-qa"]["permission"]["task"], "deny")
        for role in ("astra-orchestrator", "sol-coder", "astra-qa"):
            permissions = config["agent"][role]["permission"]
            self.assertEqual(permissions["homeassistant_*"], "deny")
            self.assertEqual(permissions["unifi_*"], "deny")
            self.assertEqual(permissions["drawio_*"], "deny")

    def test_change_after_review_invalidates_verdict(self) -> None:
        self.assertEqual(self.invoke(mode="mutate"), 2)

    def test_coder_written_approval_does_not_satisfy_gate(self) -> None:
        self.assertEqual(self.invoke(mode="fail"), 2)

    def test_failed_deterministic_check_cannot_be_overridden_by_pass(self) -> None:
        self.assertEqual(self.invoke(checks=["false"]), 2)

    def test_missing_required_check_cannot_permit_ready(self) -> None:
        self.assertEqual(self.invoke(checks=[]), 2)

    def test_repair_limit_terminates(self) -> None:
        self.assertEqual(self.invoke(checks=["false"], repairs=1), 2)

    def test_parallel_workspaces_are_distinct(self) -> None:
        # Call the implementation directly because CLI output is not the contract under test.
        root = Path(tempfile.mkdtemp(dir=self.temp.name))
        one = WORKFLOW.create_workspace(self.repo, root / "one")
        two = WORKFLOW.create_workspace(self.repo, root / "two")
        self.assertNotEqual(one, two)
        (one / "only-one").write_text("one")
        self.assertFalse((two / "only-one").exists())


if __name__ == "__main__":
    unittest.main()
