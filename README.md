# NixOS Flake

Personal NixOS flake for multiple machines and install media.

## What Is In This Repo

- Multi-host NixOS flake in `flake.nix`
- Shared modules in `common/`
- Host-specific configs in `machines/`
- Optional user environment via `hjem/`
- Per-host role and service documentation in `machines/<host>/README.md`

Hosts importing `hjem/default.nix` share the Codex Fish helper and OpenCode
configuration files from `hjem/tooling.nix`. The OpenCode package, helper
commands, and SOPS-backed MCP environment remain host-specific; currently only
battlestation provides that system setup and its credentials. The shared
OpenCode configuration uses `astra-orchestrator` to delegate implementation to
`sol-coder` and repository research to `explore`.
Explicit remote work can use `@hermes` or requested delegation to `hermes` via
the native API at `https://api.hermes.basn.se/v1`; see
[Hermes API setup and authority](machines/hermes/README.md#opencode-api).
The shared config alone does not provision credentials on laptop or other clients.
It also loads the native V2 `@dietrichgebert/ponytail` plugin in its default
`full` mode, with `/ponytail` commands for switching levels.
Sol uses native V2 ordered permissions: shell commands ask by default, with
exact exceptions for `pwd`, two Git status forms, no-pager Git diffs with
external diff/textconv disabled, and installed `nixfmt --check hjem/tooling.nix`.
Other checks, builds, mutations, and arbitrary command arguments need approval.
Saved project **Allow always** approvals can bypass `ask`; they are preserved.
This is not a sandbox: shell runs with the user's authority, and compound
commands depend on OpenCode's scanner checking each extracted command.
Built-in formatters are enabled when available; no formatter is installed here.

Hjem also manages `~/.config/opencode/cli.json` from
`hjem/configs/opencode-cli.json`, preserving the inspected battlestation
preferences (GitHub dark, word-wrapped unified diffs, automatic sidebar, hidden
scrollbar, visible thinking, animations). Laptop preferences were not inspected.
Activation replaces existing files (`clobberFiles = true`), including laptop's
CLI preferences. Change preferences in the repository: the store-backed file
may prevent persistent UI setting changes, or activation may replace them.
Offline policy checks: `python3 tests/opencode-config.py`; these simulate rule
matching, not the actual shell scanner or runtime approval behavior.

The Home Assistant and NixOS MCP launchers use the locked
`nixpkgs-unstable-small` input from the checkout at `/home/basn/nixos`, regardless
of OpenCode's working directory; keep that checkout available at this path.

## Flake Outputs

`flake.nix` is the authoritative inventory of NixOS hosts and installation
media; read it to identify affected outputs and imports.

GitHub Actions is the default build path. Every push to `main` starts
[build-cache host selection](docs/github-build-cache.md), which compares system
derivations and builds only changed hosts. Documentation-only pushes can
evaluate the fleet without host builds. Manual dispatch and missing-baseline
fallbacks select the full fleet. ISO images and dedicated test outputs are not
built by this workflow, and CI is not a deployment gate.

Run installed non-build checks first. Local builds require explicit permission,
even for a generic implementation or validation request; explain why and ask
first. Avoid incidental builds from `nix shell`, `nix run`, or evaluation using
import-from-derivation. Commit, push, PR creation, workflow dispatch, and
deployment each still require explicit authorization. Report pending CI as
pending, not passed, and give the exact revision and covered outputs when known.

### Standalone validation (local or CI)

From the checkout root, use the same entry point locally or in CI:

```sh
bash scripts/validate-flake.sh
bash scripts/validate-flake.sh --host services --host hermes
bash scripts/validate-flake.sh --all-hosts
bash scripts/validate-flake.sh --json --host services
# Only with explicit build permission:
bash scripts/validate-flake.sh --build-checks --host services --build-hosts
```

The default runs `nix flake check --no-build`. There is currently no `checks`
output; this is flake validation, not a build of all system closures.
`--build-checks` allows flake check to build declared checks, if present.
`--host` separately evaluates each selected `config.system.build.toplevel.drvPath`;
`--all-hosts` discovers names from `nixosConfigurations`, including ISO configs.
`--build-hosts` requires host selection and builds their toplevels sequentially
with `--no-link`. It never activates anything. ISO images and custom
`system.build` test outputs are not built by this command.

Every Nix call forbids lock writes and updates. Evaluation-only calls also set
`allow-import-from-derivation = false`: evaluations requiring IFD fail rather
than realizing derivations, even with `--no-build`. This can block otherwise
valid configurations; it does not prohibit input downloads, store writes, or
evaluation caches. Explicit build stages retain normal Nix IFD behavior.
Independent stages continue after failures and the final status is nonzero if
any requested stage fails. Interruptions exit 130 (INT) or 143 (TERM), mark the
running stage failed, and report work not started as skipped.
Full stdout/stderr files persist in a unique ignored
`.ci/validate-flake.*` directory, with per-stage paths in the summary; review
logs before sharing them. Unknown or non-simple host names are rejected safely.
This standalone runner does not change the existing CI selection/build policy.

`--json` requires an installed `python3` (standard-library JSON encoding only;
not needed for human output). Once validation starts, stdout contains exactly
one JSON document on success, failure, or handled INT/TERM interruption; Nix
diagnostics stay in persistent logs. The top-level `exit_code` matches the
process exit code: 0 for success, 1 for validation failure, or the signal codes
above. `stages` entries contain `stage` (`flake_check`, `host_discovery`,
`host_evaluation`, `host_build`, or `host_selection` when inventory is unavailable),
`host` (string or null), `status` (`passed`, `failed`, `skipped`), `exit_code`,
`log_path`, and `detail`. Stage exit codes are actual child results (including
the terminated child on interruption), null if not run, or synthetic 64 for an
unknown/unsupported host. `log_path` is a directory containing `stdout` and
`stderr` for executed stages; skipped stages have empty directories, and
rejected hosts have a `stderr` explanation.

`--help` prints human help and exits 0 even with `--json`. Argument errors
(exit 64) and pre-validation setup failures (exit 1, including missing Python
or log-directory creation failure) may emit stderr and no JSON. JSON encoding
failure itself exits nonzero and may leave stdout empty or incomplete.

Offline runner tests: `python3 tests/validate-flake.py` (Python standard library).

Only with explicit local-build permission, build the affected host or image
without creating a `result` symlink:

```sh
nix build .#nixosConfigurations.<host>.config.system.build.toplevel --no-link
nix build .#nixosConfigurations.<iso>.config.system.build.isoImage --no-link
```

Where present, host READMEs under `machines/` describe their role, configured
services, primary configuration files, and matching build command.
The Cygate directories document their `nixos-sov` output names.

## Repository Layout

```text
.
├── flake.nix
├── flake.lock
├── common/
├── hjem/
├── machines/
│   ├── battlestation/
│   ├── laptop/
│   ├── services/
│   └── ...
├── modules/
└── secrets/
```
