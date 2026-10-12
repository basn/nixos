# OpenCode Workflow

`hjem/configs/opencode.json` is the declarative source of truth for both Hjem
desktop hosts. Restart OpenCode after a configuration rebuild; it loads its
configuration at startup.

The default primary agent is `astra-orchestrator`. It defines scope, affected
files or hosts, and observable acceptance criteria, then delegates repository
research to `explore`, implementation to `sol-coder`, and independent review to
`astra-qa`. Coders and QA cannot delegate. QA cannot edit or use a shell.

Run an enforced implementation and QA cycle on battlestation with one line:

```sh
opencode-workflow run --task docs/my-task.md --check 'nixfmt --check hjem/configs/opencode.json' --check 'git diff --check'
```

The task document must state the requested scope and acceptance criteria. The
runner creates a detached worktree, carries tracked changes and non-ignored
untracked files into it, and never commits, merges, pushes, deploys, or switches
a NixOS generation. It runs the coder in that workspace, runs every required
check, then starts QA in a separate fresh OpenCode execution. QA receives the
actual diff and evidence and must emit exactly one snapshot-bound JSON verdict.

Only a `PASS` from that QA execution, matching the workspace content hash after
all required checks pass, prints `ready for user approval`. Missing, malformed,
stale, `FAIL`, or `BLOCKED` QA output is rejected. Any source change after QA
invalidates the approval. `FAIL` receives at most `--max-repairs` (default one)
coder repair attempt; `BLOCKED` stops immediately. The runner writes all model
and command evidence beside the disposable workspace it prints.

`parallel-workspaces` supports one or two independent writers without sharing a
writable source tree:

```sh
opencode-workflow parallel-workspaces --workers 2
```

It intentionally creates patch-handoff worktrees only. It does not merge their
patches; integrate reviewed patches manually, then run the normal single-worker
workflow on the final integrated tree. This avoids implicit commits and protects
the caller's dirty worktree.

The runner launches OpenCode with an isolated HOME/XDG state and passes only
`OPENAI_API_KEY` when present. Its overlay disables Home Assistant, UniFi, and
Draw.io MCP servers; role permissions additionally deny Home Assistant and
UniFi tool names. The NixOS documentation MCP remains in the normal declarative
configuration. This reduces accidental credential inheritance, but does not
sandbox arbitrary shell commands: a local runner is not protection against a
person or process deliberately bypassing it. GitHub required checks and branch
protection are a separate merge-enforcement layer.

`ocfg` edits the repository-managed configuration, not Hjem's generated runtime
file. The old mutable `opencode-mcp-sync` and `opencode-mcp-new` commands were
retired because they replaced that managed file. Add MCP configuration through
`hjem/configs/opencode.json` and rebuild instead. `opencode-skill-new` now
requires a lowercase hyphen-separated name of at most 64 characters and creates
valid `SKILL.md` frontmatter.
