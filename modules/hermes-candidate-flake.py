#!/usr/bin/env python3
"""Restricted basn/nixos flake-update impact audit.

The caller supplies only the freshly observed main commit. The repository,
checkout location, evaluated attributes, update command, and artifact directory
are fixed here; no arbitrary command, path, URL, build, deployment, or upload is
accepted.
"""

from __future__ import annotations

from collections import defaultdict
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import resource
import shutil
import signal
import subprocess
import sys
import tempfile
from typing import Any


AUDIT_HOME = Path("/var/lib/hermes-audit")
REPOSITORY = "https://github.com/basn/nixos.git"
MAX_ERROR_CHARS = 24_000
EXPECTED_HOSTS = {"services", "battlestation", "hermes"}
REVISION_RE = re.compile(r"^[0-9a-f]{40}$")
HOST_RE = re.compile(r"^[A-Za-z0-9_-]+$")
PACKAGE_APPLY = (
    "packages: map (package: { "
    "name = package.name or null; "
    "pname = package.pname or null; "
    "version = package.version or null; "
    "}) packages"
)
ACTIVE_PROCESS: subprocess.Popen[str] | None = None


class AuditInterrupted(Exception):
    pass


def handle_termination(signum: int, _frame: Any) -> None:
    process = ACTIVE_PROCESS
    if process is not None and process.poll() is None:
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
    raise AuditInterrupted(f"received signal {signum}")


def limited(text: str) -> str:
    if len(text) <= MAX_ERROR_CHARS:
        return text
    return text[-MAX_ERROR_CHARS:] + "\n[truncated to final 24000 characters]"


def run(command: list[str], *, cwd: Path, timeout: int) -> dict[str, Any]:
    global ACTIVE_PROCESS
    try:
        process = subprocess.Popen(
            command,
            cwd=cwd,
            env=os.environ,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            start_new_session=True,
        )
        ACTIVE_PROCESS = process
        stdout, stderr = process.communicate(timeout=timeout)
        return {
            "exit_code": process.returncode,
            "stdout": limited(stdout),
            "stderr": limited(stderr),
        }
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        try:
            stdout, stderr = process.communicate(timeout=10)
        except subprocess.TimeoutExpired:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            stdout, stderr = process.communicate()
        return {
            "exit_code": 124,
            "stdout": limited(stdout),
            "stderr": limited(stderr + f"\nTIMEOUT: exceeded {timeout} seconds"),
        }
    except OSError as error:
        return {"exit_code": 127, "stdout": "", "stderr": limited(str(error))}
    finally:
        ACTIVE_PROCESS = None


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def parse_json(command_result: dict[str, Any]) -> Any | None:
    if command_result["exit_code"] != 0:
        return None
    try:
        return json.loads(command_result["stdout"])
    except json.JSONDecodeError as error:
        command_result["exit_code"] = 65
        command_result["stderr"] = limited(
            command_result["stderr"] + f"\nINVALID_JSON_OUTPUT: {error}"
        )
        return None


def lock_inputs(path: Path) -> dict[str, dict[str, Any]]:
    raw = json.loads(path.read_text())
    result: dict[str, dict[str, Any]] = {}
    for name, node in sorted(raw.get("nodes", {}).items()):
        locked = node.get("locked") if isinstance(node, dict) else None
        if not isinstance(locked, dict):
            continue
        result[name] = {
            key: locked[key]
            for key in (
                "type",
                "owner",
                "repo",
                "rev",
                "ref",
                "narHash",
                "lastModified",
                "url",
            )
            if key in locked
        }
    return result


def changed_inputs(
    baseline: dict[str, dict[str, Any]], candidate: dict[str, dict[str, Any]]
) -> list[dict[str, Any]]:
    changes = []
    for name in sorted(set(baseline) | set(candidate)):
        before = baseline.get(name)
        after = candidate.get(name)
        if before != after:
            changes.append({"name": name, "baseline": before, "candidate": after})
    return changes


def normalize_packages(value: Any) -> list[dict[str, str | None]]:
    if not isinstance(value, list):
        return []
    normalized = []
    for package in value:
        if not isinstance(package, dict):
            continue
        record = {
            "name": package.get("name") if isinstance(package.get("name"), str) else None,
            "pname": package.get("pname") if isinstance(package.get("pname"), str) else None,
            "version": package.get("version") if isinstance(package.get("version"), str) else None,
        }
        normalized.append(record)
    return sorted(normalized, key=lambda item: json.dumps(item, sort_keys=True))


def inventory_hash(packages: list[dict[str, str | None]]) -> str:
    encoded = json.dumps(packages, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(encoded).hexdigest()


def package_key(package: dict[str, str | None]) -> str:
    return package.get("pname") or package.get("name") or "<unknown>"


def compare_packages(
    baseline: list[dict[str, str | None]], candidate: list[dict[str, str | None]]
) -> dict[str, Any]:
    before: dict[str, list[dict[str, str | None]]] = defaultdict(list)
    after: dict[str, list[dict[str, str | None]]] = defaultdict(list)
    for package in baseline:
        before[package_key(package)].append(package)
    for package in candidate:
        after[package_key(package)].append(package)

    added = []
    removed = []
    changed = []
    for key in sorted(set(before) | set(after)):
        old = before.get(key, [])
        new = after.get(key, [])
        if not old:
            added.extend(new)
        elif not new:
            removed.extend(old)
        elif old != new:
            changed.append({"package": key, "baseline": old, "candidate": new})
    return {
        "scope": "evaluated config.environment.systemPackages; not a built closure diff",
        "added": added,
        "removed": removed,
        "changed": changed,
    }


def evaluate_host(repo: Path, host: str) -> dict[str, Any]:
    if not HOST_RE.fullmatch(host):
        return {
            "system_derivation": None,
            "system_derivation_exit": 64,
            "package_inventory": [],
            "package_inventory_exit": 64,
            "errors": [f"unsafe output name rejected: {host!r}"],
        }
    prefix = f".#nixosConfigurations.{host}.config"
    derivation = run(
        [
            "nix",
            "eval",
            "--no-write-lock-file",
            "--raw",
            f"{prefix}.system.build.toplevel.drvPath",
        ],
        cwd=repo,
        timeout=600,
    )
    inventory_result = run(
        [
            "nix",
            "eval",
            "--no-write-lock-file",
            "--json",
            f"{prefix}.environment.systemPackages",
            "--apply",
            PACKAGE_APPLY,
        ],
        cwd=repo,
        timeout=600,
    )
    inventory = normalize_packages(parse_json(inventory_result))
    errors = []
    if derivation["exit_code"] != 0:
        errors.append("system derivation evaluation: " + derivation["stderr"])
    if inventory_result["exit_code"] != 0:
        errors.append("package inventory evaluation: " + inventory_result["stderr"])
    return {
        "system_derivation": derivation["stdout"].strip() or None,
        "system_derivation_exit": derivation["exit_code"],
        "package_inventory_count": len(inventory),
        "package_inventory_hash": inventory_hash(inventory),
        "package_inventory": inventory,
        "package_inventory_exit": inventory_result["exit_code"],
        "errors": errors,
    }


def host_names(repo: Path) -> tuple[list[str], dict[str, Any]]:
    result = run(
        [
            "nix",
            "eval",
            "--no-write-lock-file",
            "--json",
            ".#nixosConfigurations",
            "--apply",
            "builtins.attrNames",
        ],
        cwd=repo,
        timeout=600,
    )
    parsed = parse_json(result)
    names = sorted(name for name in (parsed or []) if isinstance(name, str))
    return names, result


def evaluate_fleet(repo: Path, names: list[str]) -> dict[str, Any]:
    return {name: evaluate_host(repo, name) for name in names}


def reportable_host_evaluation(result: dict[str, Any]) -> dict[str, Any]:
    return {key: value for key, value in result.items() if key != "package_inventory"}


def validation(repo: Path) -> dict[str, Any]:
    result = run(
        ["nix", "flake", "check", "--no-build", "--no-write-lock-file"],
        cwd=repo,
        timeout=1800,
    )
    return {
        "command": "nix flake check --no-build --no-write-lock-file",
        "exit_code": result["exit_code"],
        "stdout": result["stdout"],
        "stderr": result["stderr"],
    }


def preserve_artifact(lockfile: Path, commit: str, candidate_hash: str) -> Path:
    artifact_dir = AUDIT_HOME / "candidate-artifacts"
    artifact_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
    artifact = artifact_dir / f"{commit}-{candidate_hash}.lock"
    temporary = artifact.with_suffix(".lock.tmp")
    shutil.copyfile(lockfile, temporary)
    temporary.chmod(0o600)
    temporary.replace(artifact)
    artifacts = sorted(
        artifact_dir.glob("*.lock"), key=lambda path: path.stat().st_mtime, reverse=True
    )
    for stale in artifacts[10:]:
        stale.unlink()
    return artifact


def error_text(result: dict[str, Any]) -> str:
    return result.get("stderr", "").strip() or result.get("stdout", "").strip()


def render_summary(report: dict[str, Any]) -> str:
    lines = [
        f"Status: {report['status']}",
        f"Checked main commit: {report['checked_main_commit']}",
        f"Baseline lock SHA256: {report['baseline_lock_sha256']}",
        f"Candidate lock SHA256: {report['candidate_lock_sha256']}",
        "Lockfile unchanged by evaluation: "
        f"baseline={report['lockfile_unchanged_by_evaluation']['baseline']} "
        f"candidate={report['lockfile_unchanged_by_evaluation']['candidate']}",
        f"Candidate lock artifact: {report['candidate_lock_artifact']}",
        f"Changed inputs: {len(report['changed_inputs'])}",
    ]
    for change in report["changed_inputs"]:
        before = change.get("baseline") or {}
        after = change.get("candidate") or {}
        lines.append(
            f"  {change['name']}: {before.get('rev') or before.get('narHash') or '<absent>'}"
            f" -> {after.get('rev') or after.get('narHash') or '<absent>'}"
        )
    lines.append("Per-host evaluated differences:")
    for host, details in report["hosts"].items():
        package_diff = details["packages"]
        lines.append(
            f"  {host}: toplevel_changed={details['toplevel_changed']} "
            f"packages +{len(package_diff['added'])} "
            f"-{len(package_diff['removed'])} "
            f"~{len(package_diff['changed'])}"
        )
        for item in package_diff["changed"]:
            old_versions = sorted({record.get("version") or "?" for record in item["baseline"]})
            new_versions = sorted({record.get("version") or "?" for record in item["candidate"]})
            lines.append(
                f"    {item['package']}: {','.join(old_versions)} -> {','.join(new_versions)}"
            )
        for item in package_diff["added"]:
            lines.append(f"    + {package_key(item)} {item.get('version') or '?'}")
        for item in package_diff["removed"]:
            lines.append(f"    - {package_key(item)} {item.get('version') or '?'}")
        for error in details["errors"]:
            lines.append(f"    ERROR: {error}")
    lines.extend(
        [
            f"Baseline validation exit: {report['validation']['baseline']['exit_code']}",
            f"Candidate update exit: {report['update']['exit_code']}",
            f"Candidate validation exit: {report['validation']['candidate']['exit_code']}",
            "Coverage gaps:",
            *[f"  - {gap}" for gap in report["coverage_gaps"]],
        ]
    )
    return "\n".join(lines)


def emit(report: dict[str, Any]) -> None:
    print("CANDIDATE_AUDIT_JSON_BEGIN")
    print(json.dumps(report, indent=2, sort_keys=True))
    print("CANDIDATE_AUDIT_JSON_END")
    print("CANDIDATE_AUDIT_SUMMARY_BEGIN")
    print(render_summary(report))
    print("CANDIDATE_AUDIT_SUMMARY_END")


def main() -> int:
    if len(sys.argv) != 2 or not REVISION_RE.fullmatch(sys.argv[1]):
        return 64
    requested_commit = sys.argv[1]
    AUDIT_HOME.mkdir(mode=0o700, parents=True, exist_ok=True)
    os.environ.update(
        {
            "HOME": str(AUDIT_HOME),
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_CONFIG_GLOBAL": "/dev/null",
            "GIT_TERMINAL_PROMPT": "0",
            "NIX_CONFIG": "experimental-features = nix-command flakes",
            "NIX_PATH": "",
            "SSL_CERT_FILE": "/etc/ssl/certs/ca-certificates.crt",
        }
    )
    resource.setrlimit(resource.RLIMIT_AS, (24 * 1024**3, 24 * 1024**3))
    signal.signal(signal.SIGTERM, handle_termination)
    signal.signal(signal.SIGINT, handle_termination)
    lock_path = AUDIT_HOME / "validation.lock"
    with lock_path.open("a+") as lock_handle:
        try:
            fcntl.flock(lock_handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print("ENVIRONMENT_ERROR: another audit is running", file=sys.stderr)
            return 75

        work = Path(tempfile.mkdtemp(prefix="candidate.", dir=AUDIT_HOME))
        os.environ["XDG_CACHE_HOME"] = str(work / "cache")
        report: dict[str, Any] = {
            "schema_version": 1,
            "status": "blocked",
            "requested_main_commit": requested_commit,
            "checked_main_commit": None,
            "baseline_lock_sha256": None,
            "candidate_lock_sha256": None,
            "candidate_lock_artifact": None,
            "lockfile_unchanged_by_evaluation": {"baseline": None, "candidate": None},
            "declared_hosts": {"baseline": [], "candidate": []},
            "changed_inputs": [],
            "hosts": {},
            "update": {"exit_code": None, "stdout": "", "stderr": ""},
            "validation": {
                "baseline": {"exit_code": None, "stdout": "", "stderr": ""},
                "candidate": {"exit_code": None, "stdout": "", "stderr": ""},
            },
            "coverage_gaps": [
                "Package inventories cover evaluated config.environment.systemPackages only.",
                "No host system closure was built; toplevel comparisons are derivation-path comparisons.",
                "Transitive closure and runtime behaviour are not verified by this audit.",
                "No-build evaluation may still perform import-from-derivation work.",
                "Literal OCI image references are audited separately by basn-audit.",
            ],
        }
        exit_code = 1
        try:
            repo = work / "nixos"
            clone = run(
                [
                    "git",
                    "clone",
                    "--quiet",
                    "--depth=1",
                    "--single-branch",
                    "--branch",
                    "main",
                    REPOSITORY,
                    str(repo),
                ],
                cwd=work,
                timeout=180,
            )
            if clone["exit_code"] != 0:
                report["coverage_gaps"].append(
                    "Fresh GitHub clone failed: " + error_text(clone)
                )
                emit(report)
                return 69

            revision = run(["git", "rev-parse", "HEAD"], cwd=repo, timeout=30)
            actual_commit = revision["stdout"].strip()
            report["checked_main_commit"] = actual_commit or None
            if revision["exit_code"] != 0:
                report["coverage_gaps"].append(
                    "Could not resolve the fresh checkout commit: " + error_text(revision)
                )
                emit(report)
                return revision["exit_code"] or 1
            if actual_commit != requested_commit:
                report["coverage_gaps"].append(
                    "REVISION_CHANGED: main advanced; fetch again before candidate audit"
                )
                emit(report)
                return 75

            lockfile = repo / "flake.lock"
            report["baseline_lock_sha256"] = sha256(lockfile)
            baseline_inputs = lock_inputs(lockfile)
            baseline_names, baseline_names_result = host_names(repo)
            report["declared_hosts"]["baseline"] = baseline_names
            if baseline_names_result["exit_code"] != 0:
                report["coverage_gaps"].append(
                    "Baseline host enumeration failed: " + error_text(baseline_names_result)
                )
            missing_expected = sorted(EXPECTED_HOSTS - set(baseline_names))
            if missing_expected:
                report["coverage_gaps"].append(
                    "Required outputs missing from baseline: " + ", ".join(missing_expected)
                )
            baseline_fleet = evaluate_fleet(repo, baseline_names)
            report["validation"]["baseline"] = validation(repo)
            baseline_intact = sha256(lockfile) == report["baseline_lock_sha256"]
            report["lockfile_unchanged_by_evaluation"]["baseline"] = baseline_intact
            if not baseline_intact:
                report["coverage_gaps"].append(
                    "LOCKFILE_CHANGED: baseline evaluation or validation modified flake.lock"
                )
                emit(report)
                return 74

            update = run(["nix", "flake", "update"], cwd=repo, timeout=1800)
            report["update"] = update
            if update["exit_code"] != 0:
                report["coverage_gaps"].append(
                    "Candidate lock resolution failed: " + error_text(update)
                )
                for host, baseline in baseline_fleet.items():
                    report["hosts"][host] = {
                        "baseline": reportable_host_evaluation(baseline),
                        "candidate": None,
                        "toplevel_changed": None,
                        "packages": {
                            "scope": "evaluated config.environment.systemPackages; candidate unavailable",
                            "added": [],
                            "removed": [],
                            "changed": [],
                        },
                        "errors": ["candidate unavailable because nix flake update failed"],
                    }
                emit(report)
                return update["exit_code"] or 1

            report["candidate_lock_sha256"] = sha256(lockfile)
            candidate_inputs = lock_inputs(lockfile)
            report["changed_inputs"] = changed_inputs(baseline_inputs, candidate_inputs)
            artifact = preserve_artifact(
                lockfile, actual_commit, report["candidate_lock_sha256"]
            )
            report["candidate_lock_artifact"] = str(artifact)

            candidate_names, candidate_names_result = host_names(repo)
            report["declared_hosts"]["candidate"] = candidate_names
            if candidate_names_result["exit_code"] != 0:
                report["coverage_gaps"].append(
                    "Candidate host enumeration failed: " + error_text(candidate_names_result)
                )
            missing_expected = sorted(EXPECTED_HOSTS - set(candidate_names))
            if missing_expected:
                report["coverage_gaps"].append(
                    "Required outputs missing from candidate: " + ", ".join(missing_expected)
                )
            candidate_fleet = evaluate_fleet(repo, candidate_names)
            for host in sorted(set(baseline_names) | set(candidate_names)):
                baseline = baseline_fleet.get(host)
                candidate = candidate_fleet.get(host)
                errors = []
                if baseline is None:
                    errors.append("host added by candidate; no baseline evaluation")
                if candidate is None:
                    errors.append("host removed by candidate; no candidate evaluation")
                if baseline:
                    errors.extend(f"baseline: {error}" for error in baseline["errors"])
                if candidate:
                    errors.extend(f"candidate: {error}" for error in candidate["errors"])
                report["hosts"][host] = {
                    "baseline": reportable_host_evaluation(baseline) if baseline else None,
                    "candidate": reportable_host_evaluation(candidate) if candidate else None,
                    "toplevel_changed": (
                        baseline["system_derivation"] != candidate["system_derivation"]
                        if baseline and candidate
                        else None
                    ),
                    "packages": (
                        compare_packages(
                            baseline["package_inventory"], candidate["package_inventory"]
                        )
                        if baseline and candidate
                        else {
                            "scope": "evaluated config.environment.systemPackages; one side unavailable",
                            "added": [],
                            "removed": [],
                            "changed": [],
                        }
                    ),
                    "errors": errors,
                }

            report["validation"]["candidate"] = validation(repo)
            candidate_intact = sha256(lockfile) == report["candidate_lock_sha256"]
            report["lockfile_unchanged_by_evaluation"]["candidate"] = candidate_intact
            if not candidate_intact:
                report["coverage_gaps"].append(
                    "LOCKFILE_CHANGED: candidate evaluation or validation modified flake.lock; "
                    "the preserved artifact still contains the pre-validation candidate lock"
                )
            failures = [
                report["validation"]["baseline"]["exit_code"],
                report["validation"]["candidate"]["exit_code"],
                0 if candidate_intact else 74,
                *(item["system_derivation_exit"] for item in baseline_fleet.values()),
                *(item["package_inventory_exit"] for item in baseline_fleet.values()),
                *(item["system_derivation_exit"] for item in candidate_fleet.values()),
                *(item["package_inventory_exit"] for item in candidate_fleet.values()),
            ]
            required_hosts_present = EXPECTED_HOSTS <= set(baseline_names) and EXPECTED_HOSTS <= set(candidate_names)
            if all(code == 0 for code in failures) and required_hosts_present:
                report["status"] = "ok"
                exit_code = 0
            else:
                report["status"] = "partial"
                candidate_validation_exit = report["validation"]["candidate"]["exit_code"]
                exit_code = candidate_validation_exit or 1
            emit(report)
            return exit_code
        except AuditInterrupted as error:
            report["status"] = "blocked"
            report["coverage_gaps"].append(f"Candidate audit interrupted: {error}")
            emit(report)
            return 124
        except Exception as error:
            report["status"] = "blocked"
            report["coverage_gaps"].append(
                f"UNEXPECTED_ERROR: {type(error).__name__}: {error}"
            )
            emit(report)
            return 70
        finally:
            shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    raise SystemExit(main())
