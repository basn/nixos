"""Publish only the named desktop config; run as the Hermes service user."""

import copy
import fcntl
import os
from pathlib import Path
import sys
import tempfile

import yaml


def merge(existing, declared):
    result = copy.deepcopy(existing)
    for key, value in declared.items():
        result[key] = (
            merge(result[key], value)
            if isinstance(result.get(key), dict) and isinstance(value, dict)
            else copy.deepcopy(value)
        )
    return result


def mapping(path):
    try:
        value = yaml.safe_load(path.read_text())
    except (OSError, yaml.YAMLError):
        # Do not print parser diagnostics: config scalars can contain secrets.
        raise ValueError(f"Cannot read desktop configuration: {path}") from None
    if not isinstance(value, dict):
        raise ValueError(f"Desktop configuration must be a mapping: {path}")
    return value


def directory(path):
    if path.is_symlink():
        raise ValueError(f"Refusing symlink directory: {path}")
    path.mkdir(mode=0o700, exist_ok=True)
    if not path.is_dir():
        raise ValueError(f"Not a directory: {path}")


def provision(home, declared_path):
    profiles = home / "profiles"
    profile = profiles / "desktop"
    # Match the pinned upstream lifecycle markers. Never undo an operator's
    # stop/delete, even when its marker is empty or the profile tree is gone.
    if os.path.lexists(profiles / ".deleted" / "desktop") or os.path.lexists(
        profile / "gateway.parked"
    ):
        return
    declared = mapping(declared_path)
    directory(profiles)
    directory(profile)
    # Serialize repeat activations. Runtime state is never opened or copied.
    with (profile / ".nixos-provision.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        target = profile / "config.yaml"
        if target.is_symlink():
            raise ValueError("Refusing symlink desktop config")
        existing = mapping(target) if target.exists() else {}
        merged = merge(existing, declared)
        directory(profile / "workspace")
        if target.exists() and merged == existing:
            target.chmod(0o600)
            return
        # Same filesystem, private from creation, owned by hermes before discovery.
        fd, name = tempfile.mkstemp(prefix=".config-", dir=profile)
        try:
            with os.fdopen(fd, "w") as output:
                yaml.safe_dump(merged, output, sort_keys=False)
                output.flush()
                os.fsync(output.fileno())
            os.replace(name, target)
        finally:
            Path(name).unlink(missing_ok=True)


if __name__ == "__main__":
    provision(Path(sys.argv[1]), Path(sys.argv[2]))
