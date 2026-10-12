#!/usr/bin/env python3
"""Run one isolated implementation -> deterministic checks -> independent QA loop.

This is deliberately a local workflow gate, not a merge or deployment tool.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
from typing import Any


class WorkflowError(RuntimeError):
    pass


def run(command: list[str], *, cwd: Path, env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, cwd=cwd, env=env, text=True, capture_output=True, check=False)


def git(root: Path, *args: str) -> str:
    result = run(["git", *args], cwd=root)
    if result.returncode:
        raise WorkflowError(result.stderr.strip() or "git command failed")
    return result.stdout


def workspace_snapshot(workspace: Path) -> str:
    """Hash every tracked or non-ignored untracked file and its repository status."""
    paths = git(workspace, "ls-files", "-co", "--exclude-standard", "-z").encode().split(b"\0")
    digest = hashlib.sha256()
    digest.update(git(workspace, "rev-parse", "HEAD").encode())
    digest.update(git(workspace, "status", "--porcelain=v1", "-z").encode())
    for raw in sorted(path for path in paths if path):
        path = raw.decode("utf-8", "surrogateescape")
        target = workspace / path
        digest.update(raw + b"\0")
        if target.is_symlink():
            digest.update(b"L" + os.readlink(target).encode("utf-8", "surrogateescape"))
        elif target.is_file():
            digest.update(b"F" + target.read_bytes())
        else:
            digest.update(b"MISSING")
    return digest.hexdigest()


def copy_untracked(source: Path, workspace: Path) -> None:
    names = git(source, "ls-files", "--others", "--exclude-standard", "-z").encode().split(b"\0")
    for raw in names:
        if not raw:
            continue
        relative = Path(raw.decode("utf-8", "surrogateescape"))
        origin = source / relative
        destination = workspace / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        if origin.is_symlink():
            destination.unlink(missing_ok=True)
            destination.symlink_to(os.readlink(origin))
        else:
            shutil.copy2(origin, destination)


def create_workspace(source: Path, destination: Path) -> Path:
    result = run(["git", "worktree", "add", "--detach", str(destination), "HEAD"], cwd=source)
    if result.returncode:
        raise WorkflowError(result.stderr.strip() or "could not create worktree")
    patch = git(source, "diff", "--binary", "HEAD")
    if patch:
        applied = subprocess.run(["git", "apply", "--binary", "-"], cwd=destination, input=patch, text=True, capture_output=True)
        if applied.returncode:
            raise WorkflowError(applied.stderr.strip() or "could not apply source worktree changes")
    copy_untracked(source, destination)
    return destination


def controlled_environment(config: Path, overlay: Path, runtime: Path) -> dict[str, str]:
    config_home = runtime / "config"
    state_home = runtime / "state"
    cache_home = runtime / "cache"
    overlay.parent.mkdir(parents=True, exist_ok=True)
    (runtime / "home").mkdir(parents=True, exist_ok=True)
    (config_home / "opencode").mkdir(parents=True)
    shutil.copy2(config, config_home / "opencode" / "opencode.json")
    overlay.write_text(
        json.dumps(
            {
                "mcp": {
                    "homeassistant": {"enabled": False},
                    "unifi": {"enabled": False},
                    "drawio": {"enabled": False},
                }
            }
        )
    )
    env = {
        "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
        "HOME": str(runtime / "home"),
        "XDG_CONFIG_HOME": str(config_home),
        "XDG_STATE_HOME": str(state_home),
        "XDG_CACHE_HOME": str(cache_home),
        "OPENCODE_CONFIG": str(overlay),
        "OPENCODE_PURE": "1",
        "NO_COLOR": "1",
        "TERM": os.environ.get("TERM", "dumb"),
    }
    # Only pass the documented model API key, never the caller's complete environment.
    if os.environ.get("OPENAI_API_KEY"):
        env["OPENAI_API_KEY"] = os.environ["OPENAI_API_KEY"]
    return env


def invoke_agent(
    executable: str,
    role: str,
    prompt: str,
    workspace: Path,
    config: Path,
    runtime: Path,
) -> subprocess.CompletedProcess[str]:
    overlay = runtime / f"{role}-overlay.json"
    env = controlled_environment(config, overlay, runtime)
    # The normal definitions are subagents. The isolated overlay makes exactly one
    # role callable through the supported `opencode run --agent` primary interface.
    env["OPENCODE_CONFIG_CONTENT"] = json.dumps({"agent": {role: {"mode": "primary"}}})
    return run([executable, "run", "--auto", "--agent", role, "--dir", str(workspace), prompt], cwd=workspace, env=env)


def check_results(workspace: Path, checks: list[str]) -> list[dict[str, Any]]:
    results = []
    for command in checks:
        result = run(["bash", "-lc", command], cwd=workspace)
        results.append(
            {
                "command": command,
                "returncode": result.returncode,
                "stdout": result.stdout,
                "stderr": result.stderr,
            }
        )
    return results


def parse_verdict(output: str, snapshot: str) -> dict[str, Any]:
    lines = [line.strip() for line in output.splitlines() if line.strip()]
    if len(lines) != 1:
        raise WorkflowError("QA output must be exactly one JSON object")
    try:
        verdict = json.loads(lines[0])
    except json.JSONDecodeError as error:
        raise WorkflowError(f"QA output is malformed JSON: {error.msg}") from error
    required = {"verdict", "snapshot", "findings", "verification", "skipped"}
    if not isinstance(verdict, dict) or set(verdict) != required:
        raise WorkflowError("QA result has an invalid schema")
    if verdict["verdict"] not in {"PASS", "FAIL", "BLOCKED"}:
        raise WorkflowError("QA verdict must be PASS, FAIL, or BLOCKED")
    if verdict["snapshot"] != snapshot:
        raise WorkflowError("QA verdict does not bind to the reviewed snapshot")
    if not all(isinstance(verdict[key], list) for key in ("findings", "verification", "skipped")):
        raise WorkflowError("QA findings, verification, and skipped fields must be lists")
    if verdict["verdict"] == "PASS" and not verdict["verification"]:
        raise WorkflowError("PASS QA verdict lacks verification evidence")
    return verdict


def write_evidence(path: Path, name: str, value: Any) -> None:
    (path / name).write_text(json.dumps(value, indent=2, sort_keys=True) + "\n")


def qa_prompt(task: str, snapshot: str, evidence: Path) -> str:
    return f"""Independently review this integrated repository change.

Original task and acceptance criteria:
{task}

Reviewed immutable snapshot: {snapshot}
Evidence directory: {evidence}
`diff.patch` contains the integrated diff and `checks.json` contains deterministic check results.
Inspect the actual files as needed. You must not edit anything. Return exactly one JSON object with this schema and no markdown:
{{"verdict":"PASS|FAIL|BLOCKED","snapshot":"{snapshot}","findings":[],"verification":[],"skipped":[]}}
PASS requires that the implementation satisfies the task, the supplied deterministic checks passed, and there is sufficient review evidence. Include exact commands and results in verification and every omitted check in skipped. Missing, malformed, failed, blocked, or stale evidence must not be PASS."""


def run_workflow(args: argparse.Namespace) -> int:
    source = Path(args.repo).resolve()
    config = Path(args.config or source / "hjem/configs/opencode.json").resolve()
    task = Path(args.task).read_text().strip()
    if not task:
        raise WorkflowError("task file is empty")
    if not config.is_file():
        raise WorkflowError(f"OpenCode config not found: {config}")
    if not args.check:
        raise WorkflowError("at least one required deterministic --check is required")
    git(source, "rev-parse", "--show-toplevel")
    run_root = Path(tempfile.mkdtemp(prefix="opencode-workflow-"))
    workspace = create_workspace(source, run_root / "workspace")
    evidence = run_root / "evidence"
    evidence.mkdir()
    write_evidence(evidence, "task.json", {"task": task, "source_snapshot": workspace_snapshot(workspace)})

    repair_context = ""
    for attempt in range(args.max_repairs + 1):
        coder_prompt = f"""Implement this repository task in the assigned worktree. Do not commit, push, deploy, update flake inputs, or modify live services. Run the relevant checks and report their commands/results in your final response.

Original task and acceptance criteria:
{task}
{repair_context}"""
        coder = invoke_agent(args.opencode, "sol-coder", coder_prompt, workspace, config, run_root / f"coder-{attempt}")
        write_evidence(evidence, f"coder-{attempt}.json", {"returncode": coder.returncode, "stdout": coder.stdout, "stderr": coder.stderr})
        if coder.returncode:
            raise WorkflowError(f"coder execution failed on attempt {attempt}; evidence: {evidence}")

        checks = check_results(workspace, args.check)
        write_evidence(evidence, "checks.json", checks)
        if any(result["returncode"] != 0 for result in checks):
            if attempt == args.max_repairs:
                raise WorkflowError(f"deterministic checks failed after {attempt} repair attempts; evidence: {evidence}")
            repair_context = "\nRepair the failed deterministic checks recorded in evidence/checks.json."
            continue

        diff = git(workspace, "diff", "--binary", "HEAD")
        (evidence / "diff.patch").write_text(diff)
        snapshot = workspace_snapshot(workspace)
        qa = invoke_agent(args.opencode, "astra-qa", qa_prompt(task, snapshot, evidence), workspace, config, run_root / f"qa-{attempt}")
        write_evidence(evidence, f"qa-{attempt}.json", {"returncode": qa.returncode, "stdout": qa.stdout, "stderr": qa.stderr})
        if qa.returncode:
            raise WorkflowError(f"QA execution failed; no approval granted; evidence: {evidence}")
        verdict = parse_verdict(qa.stdout, snapshot)
        if workspace_snapshot(workspace) != snapshot:
            raise WorkflowError(f"reviewed workspace changed after QA; approval invalidated; evidence: {evidence}")
        write_evidence(evidence, "verdict.json", verdict)
        if verdict["verdict"] == "PASS":
            print(json.dumps({"status": "ready for user approval", "workspace": str(workspace), "snapshot": snapshot, "evidence": str(evidence)}))
            return 0
        if verdict["verdict"] == "BLOCKED":
            raise WorkflowError(f"QA is BLOCKED; no approval granted; evidence: {evidence}")
        if attempt == args.max_repairs:
            raise WorkflowError(f"QA failed after {attempt} repair attempts; evidence: {evidence}")
        repair_context = "\nQA failed. Read the independent report in evidence/qa-{}.json and fix only its findings.".format(attempt)
    raise AssertionError("unreachable")


def prepare_parallel(args: argparse.Namespace) -> int:
    source = Path(args.repo).resolve()
    if not 1 <= args.workers <= 2:
        raise WorkflowError("parallel mode supports one or two workers")
    root = Path(tempfile.mkdtemp(prefix="opencode-parallel-"))
    paths = [str(create_workspace(source, root / f"worker-{index}")) for index in range(args.workers)]
    print(json.dumps({"status": "patch handoff required", "workspaces": paths}))
    return 0


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description=__doc__)
    result.add_argument("--opencode", default="opencode")
    result.add_argument("--repo", default=".")
    result.add_argument("--config")
    commands = result.add_subparsers(dest="command", required=True)
    workflow = commands.add_parser("run", help="run the enforced implementation and QA loop")
    workflow.add_argument("--task", required=True, help="Markdown task with scope and acceptance criteria")
    workflow.add_argument("--check", action="append", default=[], help="required deterministic command; repeatable")
    workflow.add_argument("--max-repairs", type=int, default=1)
    parallel = commands.add_parser("parallel-workspaces", help="create isolated patch-handoff workspaces")
    parallel.add_argument("--workers", type=int, required=True)
    return result


def main(argv: list[str] | None = None) -> int:
    args = parser().parse_args(argv)
    if getattr(args, "max_repairs", 0) < 0:
        raise WorkflowError("max-repairs must be zero or greater")
    try:
        return run_workflow(args) if args.command == "run" else prepare_parallel(args)
    except WorkflowError as error:
        print(f"BLOCKED: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
