"""Offline tests for the SSH command boundary and validator exit-status contract.

Usage: python3 tests/hermes-audit.py /nix/store/.../bin/hermes-audit-dispatch
The dispatcher must be the built nixos-sov variant. No SSH connections are made.
"""
import fcntl
import os
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile


dispatcher = sys.argv[1]
revision = "a" * 40
for command in [
    "", "bash", "health; id", "health\nid", "health extra",
    "validate", "validate ../repo", f"validate {revision}; id",
    f"validate {revision}\nhealth", "validate " + "a" * 41,
    "validate " + "A" * 40, "scp -t /tmp/file", "internal-sftp",
]:
    result = subprocess.run(
        [dispatcher], env={**os.environ, "SSH_ORIGINAL_COMMAND": command},
        capture_output=True, text=True, check=False,
    )
    assert result.returncode == 64, (command, result.returncode, result.stderr)
print("PASS: 13 disallowed SSH commands rejected with exit 64")

source = Path("modules/hermes-validate-flake.sh").read_text()
with tempfile.TemporaryDirectory(prefix="hermes-validator-test-") as tmp:
    root = Path(tmp)
    home = root / "home"
    home.mkdir()
    bindir = root / "bin"
    bindir.mkdir()
    script = root / "validate.sh"
    script.write_text(source.replace(
        "export HOME=/var/lib/hermes-audit", f"export HOME={shlex.quote(str(home))}"
    ))
    git = bindir / "git"
    git.write_text(f"#!{sys.executable}\n" + '''
import os, pathlib, sys
if sys.argv[1] == 'clone':
    assert sys.argv[2:7] == ['--quiet','--depth=1','--single-branch','--branch','main']
    assert sys.argv[-2] == 'https://github.com/basn/nixos.git'
    if os.environ.get('TEST_CLONE_FAIL'): sys.exit(1)
    repo=pathlib.Path(sys.argv[-1]); repo.mkdir(); (repo/'flake.lock').write_text('locked')
elif sys.argv[1:] == ['rev-parse','HEAD']:
    print(os.environ['TEST_REV'])
else:
    raise AssertionError(sys.argv)
''')
    nix = bindir / "nix"
    nix.write_text(f"#!{sys.executable}\n" + '''
import os, pathlib, sys
if sys.argv[1:] == ['eval','--no-write-lock-file','--raw','.#nixosConfigurations.hermes.config.system.build.toplevel.drvPath']:
    sys.exit(int(os.environ.get('TEST_MATERIALIZE_EXIT','0')))
assert sys.argv[1:] == ['flake','check','--no-build','--no-write-lock-file']
if os.environ.get('TEST_MUTATE_LOCK'): pathlib.Path('flake.lock').write_text('changed')
sys.exit(int(os.environ.get('TEST_NIX_EXIT','0')))
''')
    git.chmod(0o755)
    nix.chmod(0o755)
    env = {**os.environ, "PATH": str(bindir) + ":" + os.environ["PATH"], "TEST_REV": revision}

    def run(expected, **extra):
        result = subprocess.run(
            ["bash", "-euo", "pipefail", str(script), revision],
            env={**env, **extra}, capture_output=True, text=True, check=False,
        )
        assert result.returncode == expected, (expected, result.returncode, result.stdout, result.stderr)
        assert not list(home.glob("check.*")), "temporary checkout was not cleaned up"
        return result.stdout + result.stderr

    assert "HERMES_MATERIALIZE_EXIT=0" in run(0)
    assert "NIX_FLAKE_CHECK_EXIT=0" in run(0, TEST_MATERIALIZE_EXIT="1")
    assert "NIX_FLAKE_CHECK_EXIT=37" in run(37, TEST_NIX_EXIT="37")
    assert "ENVIRONMENT_ERROR" in run(69, TEST_CLONE_FAIL="1")
    assert "REVISION_CHANGED" in run(75, TEST_REV="b" * 40)
    assert "LOCKFILE_CHANGED" in run(74, TEST_MUTATE_LOCK="1")
    run(37, TEST_MUTATE_LOCK="1", TEST_NIX_EXIT="37")
    with (home / "validation.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        run(75)
print("PASS: success, Nix failure, clone failure, moved main, lock integrity, cleanup, and serialization")
