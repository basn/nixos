"""Offline provisioning checks; no Hermes state or Docker access."""

import importlib.util
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import yaml

spec = importlib.util.spec_from_file_location(
    "provision", Path(__file__).with_name("provision-desktop-profile.py")
)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ProvisionTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.declared = self.home / "declared.yaml"
        self.declared.write_text("terminal:\n  docker_volumes: [desktop]\nmodel: new\n")
        self.profile = self.home / "profiles" / "desktop"
        self.target = self.profile / "config.yaml"

    def provision(self):
        module.provision(self.home, self.declared)

    def test_atomic_private_publication_and_repeat(self):
        replace = os.replace

        def observe(source, target):
            self.assertTrue((self.profile / "workspace").is_dir())
            self.assertFalse(self.target.exists())
            self.assertEqual(Path(source).stat().st_mode & 0o777, 0o600)
            self.assertEqual(Path(source).stat().st_uid, os.getuid())
            replace(source, target)

        with patch.object(module.os, "replace", side_effect=observe):
            self.provision()
        stat = self.target.stat()
        self.provision()
        self.assertEqual(self.target.stat().st_ino, stat.st_ino)
        self.assertEqual(self.target.stat().st_mtime_ns, stat.st_mtime_ns)
        self.assertFalse(list(self.profile.glob(".config-*")))

    def test_merge_preserves_state_and_replaces_lists(self):
        self.profile.mkdir(parents=True)
        self.target.write_text(
            "terminal:\n  docker_volumes: [audit, other]\n  runtime: kept\n"
            "model: old\nunknown: preserved\n"
        )
        state = {}
        for name in ("auth.json", ".env", "state.db", "cron/jobs.json"):
            path = self.profile / name
            path.parent.mkdir(exist_ok=True)
            path.write_bytes(b"opaque runtime state")
            state[path] = path.stat()
        self.provision()
        result = yaml.safe_load(self.target.read_text())
        self.assertEqual(result["terminal"], {"docker_volumes": ["desktop"], "runtime": "kept"})
        self.assertEqual(result["unknown"], "preserved")
        self.assertEqual(result["model"], "new")
        for path, before in state.items():
            self.assertEqual(path.read_bytes(), b"opaque runtime state")
            after = path.stat()
            for field in ("st_ino", "st_mode", "st_uid", "st_gid", "st_mtime_ns"):
                self.assertEqual(getattr(after, field), getattr(before, field))

    def test_malformed_existing_rejected_without_publication(self):
        self.profile.mkdir(parents=True)
        for text in ("secret: [broken", "[]", "", "null"):
            self.target.write_text(text)
            with self.assertRaises(ValueError):
                self.provision()
            self.assertEqual(self.target.read_text(), text)
            self.assertFalse((self.profile / "workspace").exists())

    def test_lifecycle_markers_not_resurrected(self):
        marker = self.home / "profiles" / ".deleted" / "desktop"
        marker.parent.mkdir(parents=True)
        marker.touch()
        self.provision()
        self.assertFalse(self.profile.exists())
        marker.unlink()
        self.profile.mkdir()
        (self.profile / "gateway.parked").touch()
        self.provision()
        self.assertFalse(self.target.exists())

    def test_symlink_config_refused(self):
        self.profile.mkdir(parents=True)
        self.target.symlink_to(self.declared)
        with self.assertRaises(ValueError):
            self.provision()


if __name__ == "__main__":
    unittest.main()
