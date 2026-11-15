"""Offline runner contract tests; no real Nix calls or builds.

Usage: python3 tests/validate-flake.py
"""
import json
import os
from pathlib import Path
import signal
import shutil
import subprocess
import sys
import tempfile
import time


script = Path(__file__).resolve().parents[1] / "scripts/validate-flake.sh"
bash = shutil.which('bash')
with tempfile.TemporaryDirectory(prefix="validate-flake-test-") as tmp:
    root = Path(tmp) / 'checkout "quoted" \\ path\nline'
    root.mkdir()
    bindir = root / "bin"
    bindir.mkdir()
    calls = root / "calls.jsonl"
    nix = bindir / "nix"
    nix.write_text(f"#!{sys.executable}\n" + '''
import json, os, pathlib, re, subprocess, sys, time
args = sys.argv[1:]
assert '--no-write-lock-file' in args and '--no-update-lock-file' in args, args
if args[0] == 'eval' or '--no-build' in args:
    i = args.index('--option')
    assert args[i+1:i+3] == ['allow-import-from-derivation', 'false'], args
else:
    assert '--option' not in args, args
with open(os.environ['CALLS'], 'a') as f:
    f.write(json.dumps(args) + '\\n')
# Exclusive creation detects any overlapping stages, including host builds.
active = pathlib.Path('active')
with active.open('x'):
    pass
try:
    print('diagnostic stderr', file=sys.stderr, flush=True)
    stage = 'check'
    if args[0] == 'eval' and '.#nixosConfigurations' in args:
        stage = 'discovery'
        assert args[-2:] == ['--apply', 'configs: builtins.concatStringsSep "\\\\n" (builtins.attrNames configs)'], args
        print(os.environ.get('INVENTORY', 'alpha\\nbeta\\nminimalIso'), end='')
    elif args[0] in ('eval', 'build'):
        target = next(arg for arg in args if arg.startswith('.#'))
        match = re.fullmatch(r'\\.#nixosConfigurations\\."([a-zA-Z0-9_-]+)"\\.config\\.system\\.build\\.toplevel(\\.drvPath)?', target)
        assert match, args
        stage = args[0] + ':' + match[1]
        assert bool(match[2]) == (args[0] == 'eval'), args
        if args[0] == 'build': assert '--no-link' in args, args
        print('diagnostic stdout', flush=True)
    else:
        assert args[:2] == ['flake', 'check'], args
        print('diagnostic stdout', flush=True)
    if os.environ.get('BLOCK') == stage:
        child = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(60)'])
        pathlib.Path('blocked').write_text(json.dumps([os.getpid(), child.pid]))
        time.sleep(60)
    time.sleep(0.01)
    sys.exit(23 if stage in os.environ.get('FAIL', '').split(',') else 0)
finally:
    active.unlink()
''')
    nix.chmod(0o755)
    env = {**os.environ, "PATH": str(bindir) + ":" + os.environ["PATH"], "CALLS": str(calls)}

    def run(args=(), expected=0, **extra):
        calls.unlink(missing_ok=True)
        result = subprocess.run(
            [bash, str(script), *args], cwd=root, env={**env, **extra},
            capture_output=True, text=True, timeout=15, check=False,
        )
        assert result.returncode == expected, (args, result.returncode, result.stdout, result.stderr)
        assert 'diagnostic stdout' not in result.stdout and 'diagnostic stderr' not in result.stderr
        commands = [json.loads(line) for line in calls.read_text().splitlines()] if calls.exists() else []
        return result.stdout, commands

    output, commands = run()
    assert len(commands) == 1 and '--no-build' in commands[0]
    assert 'passed: flake\\ check' in output
    first_logs = set((root / '.ci').iterdir())
    output, commands = run(['--build-checks'])
    assert len(commands) == 1 and '--no-build' not in commands[0]
    assert len(set((root / '.ci').iterdir()) - first_logs) == 1
    for args in [['--host'], ['--host', '--all-hosts'], ['--host', ''], ['--oops'], ['alpha'], ['--build-hosts']]:
        _, commands = run(args, expected=64)
        assert not commands
    output, commands = run(['--help'])
    assert 'Usage:' in output and not commands
    print('PASS: defaults, build opt-in, help, argument errors, unique log directories')

    output, commands = run(['--host', 'beta', '--host', 'alpha', '--host', 'beta', '--build-hosts'])
    assert [cmd[0] for cmd in commands] == ['flake', 'eval', 'eval', 'build', 'eval', 'build']
    assert '"beta"' in commands[2][-1] and '"alpha"' in commands[4][-1]
    assert output.count('passed: evaluate') == 2 and output.count('passed: build') == 2
    output, commands = run(['--all-hosts', '--host', 'alpha'])
    assert len(commands) == 5 and any('minimalIso' in arg for cmd in commands for arg in cmd)
    previous_logs = set((root / '.ci').iterdir())
    output, commands = run(['--all-hosts'], INVENTORY='')
    empty_inventory_log, = set((root / '.ci').iterdir()) - previous_logs
    assert len(commands) == 2
    print('PASS: repeatable/deduplicated selection, dynamic inventory including ISO, sequential builds')

    for bad in ['unknown', 'alpha;touch injected', '$(touch injected)', 'alpha".config', 'alpha\nbeta']:
        output, commands = run(['--host', bad, '--host', 'alpha', '--build-hosts'], expected=1)
        assert len(commands) == 4 and 'unknown or unsupported host name' in output
        assert 'skipped:' in output and '(host evaluation failed)' in output and 'passed: build\\ alpha' in output
        assert not (root / 'injected').exists()
    output, commands = run(['--all-hosts'], expected=1, INVENTORY='alpha\nevil"${throw "bad"}')
    assert len(commands) == 3 and 'unknown or unsupported host name' in output
    print('PASS: unknown and malicious names rejected without interpretation; known hosts continue')

    output, commands = run(['--all-hosts', '--build-hosts'], expected=1, FAIL='check,eval:alpha,build:beta')
    assert len(commands) == 7
    assert 'failed: flake\\ check' in output and 'failed: evaluate\\ alpha' in output
    assert 'skipped: build\\ alpha (host evaluation failed)' in output
    assert 'failed: build\\ beta' in output and 'passed: build\\ minimalIso' in output
    output, commands = run(['--host', 'alpha'], expected=1, FAIL='discovery')
    assert len(commands) == 2 and 'skipped: evaluate\\ alpha (not started)' in output
    output, commands = run(['--all-hosts'], expected=1, FAIL='discovery')
    assert 'inventory\\ unavailable' in output
    for directory in (root / '.ci').iterdir():
        for stdout in directory.glob('*/stdout'):
            assert stdout.with_name('stderr').read_text() == 'diagnostic stderr\n'
            if stdout == empty_inventory_log / '1/stdout':
                assert stdout.read_text() == ''
            else:
                assert stdout.read_text(), stdout
    print('PASS: independent failures aggregate, dependency skips, discovery failure, full stdout/stderr logs')

    def parse_summary(output, expected):
        report = json.loads(output)  # Parse all stdout, not just the last line.
        assert report['exit_code'] == expected, report
        for stage in report['stages']:
            assert stage['stage'] in {'flake_check', 'host_discovery', 'host_selection', 'host_evaluation', 'host_build'}
            assert stage['host'] is None or isinstance(stage['host'], str)
            assert stage['status'] in {'passed', 'failed', 'skipped'}
            code = stage['exit_code']
            assert code is None or type(code) is int
            assert (code is None) == (stage['status'] == 'skipped'), stage
            assert (code == 0) == (stage['status'] == 'passed'), stage
            log = Path(stage['log_path'])
            assert log.is_dir() and log.parent.parent == root / '.ci', log
            if code is not None and code != 64:
                assert (log / 'stdout').is_file()
                assert (log / 'stderr').read_text() == 'diagnostic stderr\n'
        return report['stages']

    output, commands = run(['--json', '--all-hosts', '--build-hosts'])
    stages = parse_summary(output, 0)
    assert len(stages) == 8 and all(s['status'] == 'passed' for s in stages)
    assert stages[0]['host'] is None and stages[1]['host'] is None
    assert [s['host'] for s in stages[2:]] == ['alpha', 'alpha', 'beta', 'beta', 'minimalIso', 'minimalIso']
    assert len(commands) == 8
    output, commands = run(['--json', '--all-hosts', '--build-hosts'], expected=1,
                           FAIL='check,eval:alpha,build:beta')
    stages = parse_summary(output, 1)
    assert [s['exit_code'] for s in stages] == [23, 0, 23, None, 0, 23, 0, 0]
    assert stages[3]['detail'] == 'host evaluation failed' and len(commands) == 7
    # Isolate a host failure: later successful stages must not erase it.
    output, commands = run(['--json', '--all-hosts'], expected=1, FAIL='eval:alpha')
    stages = parse_summary(output, 1)
    assert [s['exit_code'] for s in stages] == [0, 0, 23, 0, 0]
    bad = 'unknown "host" \\ newline\n\ttab'
    output, commands = run(['--json', '--host', bad, '--host', 'alpha', '--build-hosts'], expected=1)
    stages = parse_summary(output, 1)
    assert stages[2]['host'] == bad and stages[2]['exit_code'] == 64
    assert stages[3]['exit_code'] is None and stages[-1]['status'] == 'passed'
    assert (Path(stages[2]['log_path']) / 'stderr').read_text().endswith(': unknown or unsupported host name\n')
    assert len(commands) == 4 and 'diagnostic stdout' not in output and 'diagnostic stderr' not in output
    for selection in [['--host', 'alpha', '--build-hosts'], ['--all-hosts']]:
        output, commands = run(['--json', *selection], expected=1, FAIL='discovery')
        stages = parse_summary(output, 1)
        assert stages[1]['exit_code'] == 23 and len(commands) == 2
        assert all(s['status'] == 'skipped' for s in stages[2:])
    output, commands = run(['--json', '--all-hosts'], INVENTORY='')
    assert len(parse_summary(output, 0)) == 2
    for args in [['--json', '--oops'], ['--json', '--build-hosts']]:
        output, commands = run(args, expected=64)
        assert not output and not commands
    output, commands = run(['--json', '--help'])
    assert 'Usage:' in output and not commands
    output, commands = run(['--json'], expected=1, PATH=str(bindir))
    assert output == '' and not commands
    encoder = bindir / 'python3'
    encoder.write_text('#!/bin/sh\necho "encoder failure" >&2\nexit 42\n')
    encoder.chmod(0o755)
    output, commands = run(['--json'], expected=1)
    assert output == '' and len(commands) == 1
    output, commands = run()
    assert 'passed: flake\\ check' in output and len(commands) == 1
    encoder.unlink()
    print('PASS: complete JSON, stage/aggregate codes, continuation, skips, escaping, logs, diagnostics isolation, encoder failure')

    # Signal only the runner: it must stop its separate Nix process group too.
    for sig, expected, json_mode in [(sig, code, mode) for sig, code in
                                    [(signal.SIGTERM, 143), (signal.SIGINT, 130)] for mode in [False, True]]:
        (root / 'blocked').unlink(missing_ok=True)
        process = subprocess.Popen(
            ['bash', str(script), '--host', 'alpha', '--build-hosts', *(['--json'] if json_mode else [])], cwd=root,
            env={**env, 'BLOCK': 'eval:alpha'}, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            text=True, start_new_session=True,
        )
        deadline = time.monotonic() + 10
        while not (root / 'blocked').exists() and process.poll() is None and time.monotonic() < deadline:
            time.sleep(0.01)
        assert (root / 'blocked').exists(), 'stub did not reach blocking stage'
        pids = json.loads((root / 'blocked').read_text())
        process.send_signal(sig)
        output, stderr = process.communicate(timeout=5)
        assert process.returncode == expected, (process.returncode, output, stderr)
        if json_mode:
            stages = parse_summary(output, expected)
            assert stages[2]['status'] == 'failed' and stages[2]['exit_code'] in [137, 143]
            assert stages[2]['detail'] == 'interrupted before completion'
            assert stages[3]['status'] == 'skipped' and stages[3]['exit_code'] is None
        else:
            assert 'failed: evaluate\\ alpha (interrupted before completion)' in output
            assert 'skipped: build\\ alpha (not started)' in output
        for pid in pids:
            status = Path(f'/proc/{pid}/stat')
            # SIGKILL delivery to grandchildren can finish after the runner exits.
            deadline = time.monotonic() + 5
            while True:
                try:
                    state = status.read_text().split()[2]
                except FileNotFoundError:
                    break
                if state == 'Z':
                    break
                assert time.monotonic() < deadline, f'orphan process {pid} (state {state})'
                time.sleep(0.01)
        (root / 'active').unlink(missing_ok=True)
    print('PASS: TERM/INT exit nonzero, summarize unfinished stages, stop Nix and its child')
