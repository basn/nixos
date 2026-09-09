"""Offline tests for the SSH command boundary and validator exit-status contract.

Usage: python3 tests/hermes-audit.py /nix/store/.../bin/hermes-audit-dispatch
The dispatcher must be the built nixos-sov variant. No SSH connections are made.
"""
import fcntl
import json
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
    "validate " + "A" * 40,
    "candidate", "candidate ../repo", f"candidate {revision}; id",
    f"candidate {revision}\nhealth", "candidate " + "a" * 41,
    "candidate " + "A" * 40, "scp -t /tmp/file", "internal-sftp",
]:
    result = subprocess.run(
        [dispatcher], env={**os.environ, "SSH_ORIGINAL_COMMAND": command},
        capture_output=True, text=True, check=False,
    )
    assert result.returncode == 64, (command, result.returncode, result.stderr)
print("PASS: 19 disallowed SSH commands rejected with exit 64")

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

candidate_source = Path("modules/hermes-candidate-flake.py").read_text()
with tempfile.TemporaryDirectory(prefix="hermes-candidate-test-") as tmp:
    root = Path(tmp)
    home = root / "home"
    home.mkdir()
    bindir = root / "bin"
    bindir.mkdir()
    script = root / "candidate.py"
    script.write_text(candidate_source.replace(
        'AUDIT_HOME = Path("/var/lib/hermes-audit")',
        f"AUDIT_HOME = Path({str(home)!r})",
    ))
    git = bindir / "git"
    git.write_text(f"#!{sys.executable}\n" + '''
import json, os, pathlib, sys
if sys.argv[1] == 'clone':
    assert sys.argv[2:7] == ['--quiet','--depth=1','--single-branch','--branch','main']
    assert sys.argv[-2] == 'https://github.com/basn/nixos.git'
    repo = pathlib.Path(sys.argv[-1])
    repo.mkdir()
    lock = {'nodes': {'sample': {'locked': {'type': 'github', 'owner': 'example', 'repo': 'sample', 'rev': '1' * 40, 'narHash': 'sha256-old'}}}, 'root': 'sample', 'version': 7}
    (repo / 'flake.lock').write_text(json.dumps(lock))
elif sys.argv[1:] == ['rev-parse', 'HEAD']:
    print(os.environ['TEST_REV'])
else:
    raise AssertionError(sys.argv)
''')
    nix = bindir / "nix"
    nix.write_text(f"#!{sys.executable}\n" + '''
import json, os, pathlib, re, sys
args = sys.argv[1:]
if args == ['flake', 'update']:
    if os.environ.get('TEST_UPDATE_FAIL'):
        print('simulated update failure', file=sys.stderr)
        sys.exit(42)
    if os.environ.get('TEST_UPDATE_CHANGE'):
        path = pathlib.Path('flake.lock')
        lock = json.loads(path.read_text())
        lock['nodes']['sample']['locked']['rev'] = '2' * 40
        lock['nodes']['sample']['locked']['narHash'] = 'sha256-new'
        path.write_text(json.dumps(lock))
    sys.exit(0)
if args == ['flake', 'check', '--no-build', '--no-write-lock-file']:
    sys.exit(0)
if args[:4] == ['eval', '--no-write-lock-file', '--json', '.#nixosConfigurations']:
    assert args[4:] == ['--apply', 'builtins.attrNames']
    print(json.dumps(['services', 'battlestation', 'hermes']))
    sys.exit(0)
if args[:3] == ['eval', '--no-write-lock-file', '--raw']:
    match = re.search(r'nixosConfigurations\\.([^.]+)', args[3])
    assert match, args
    lock = json.loads(pathlib.Path('flake.lock').read_text())
    state = 'candidate' if lock['nodes']['sample']['locked']['rev'].startswith('2') else 'baseline'
    print(f'/nix/store/{state}-{match.group(1)}.drv', end='')
    sys.exit(0)
if args[:3] == ['eval', '--no-write-lock-file', '--json'] and '.environment.systemPackages' in args[3]:
    assert args[4] == '--apply'
    lock = json.loads(pathlib.Path('flake.lock').read_text())
    version = '2.0' if lock['nodes']['sample']['locked']['rev'].startswith('2') else '1.0'
    print(json.dumps([{'name': f'sample-{version}', 'pname': 'sample', 'version': version}]))
    sys.exit(0)
raise AssertionError(args)
''')
    git.chmod(0o755)
    nix.chmod(0o755)
    env = {
        **os.environ,
        "PATH": str(bindir) + ":" + os.environ["PATH"],
        "TEST_REV": revision,
    }

    def run_candidate(expected, **extra):
        result = subprocess.run(
            [sys.executable, str(script), revision],
            env={**env, **extra}, capture_output=True, text=True, check=False,
        )
        assert result.returncode == expected, (expected, result.returncode, result.stdout, result.stderr)
        assert not list(home.glob("candidate.*")), "disposable candidate checkout was not cleaned up"
        begin = result.stdout.index("CANDIDATE_AUDIT_JSON_BEGIN\n") + len("CANDIDATE_AUDIT_JSON_BEGIN\n")
        end = result.stdout.index("\nCANDIDATE_AUDIT_JSON_END")
        return json.loads(result.stdout[begin:end]), result.stdout + result.stderr

    report, output = run_candidate(0)
    assert report["status"] == "ok"
    assert report["changed_inputs"] == []
    assert report["declared_hosts"]["baseline"] == ["battlestation", "hermes", "services"]
    assert report["declared_hosts"]["candidate"] == ["battlestation", "hermes", "services"]
    assert all(details["toplevel_changed"] is False for details in report["hosts"].values())
    assert all(not details["packages"]["added"] for details in report["hosts"].values())
    assert all(not details["packages"]["removed"] for details in report["hosts"].values())
    assert all(not details["packages"]["changed"] for details in report["hosts"].values())
    artifact = Path(report["candidate_lock_artifact"])
    assert artifact.is_file() and artifact.stat().st_mode & 0o777 == 0o600
    assert "Candidate validation exit: 0" in output

    report, output = run_candidate(0, TEST_UPDATE_CHANGE="1")
    assert report["status"] == "ok"
    assert [change["name"] for change in report["changed_inputs"]] == ["sample"]
    assert all(details["toplevel_changed"] is True for details in report["hosts"].values())
    for details in report["hosts"].values():
        assert details["packages"]["changed"] == [{
            "package": "sample",
            "baseline": [{"name": "sample-1.0", "pname": "sample", "version": "1.0"}],
            "candidate": [{"name": "sample-2.0", "pname": "sample", "version": "2.0"}],
        }]
    assert "sample: 1.0 -> 2.0" in output

    report, output = run_candidate(42, TEST_UPDATE_FAIL="1")
    assert report["status"] == "blocked"
    assert report["update"]["exit_code"] == 42
    assert report["validation"]["candidate"]["exit_code"] is None
    assert report["candidate_lock_artifact"] is None
    assert "Candidate lock resolution failed: simulated update failure" in output
print("PASS: candidate unchanged/changed comparisons, artifact, structured failure, and cleanup contracts")
