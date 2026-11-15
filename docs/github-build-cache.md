# GitHub build cache and nightly upgrades

The repository uses a build-and-cache model. GitHub Actions never connects to
machines over SSH and never activates a NixOS configuration.

## Default validation path

Use GitHub Actions for builds by default and installed non-build checks locally.
Local builds require explicit permission: explain why and ask first; a generic
implementation or validation request is not permission. This includes incidental
builds through `nix shell`, `nix run`, or import-from-derivation during evaluation.
Do not fetch missing check tools if that would require an unauthorized build.
Commit, push, PR creation, manual workflow dispatch, and deployment still require
explicit authorization.

Distinguish pending or unobserved CI from passed CI. When available, report the
run's exact revision and selected, built, and unchanged outputs. Fleet CI does
not build ISO images or dedicated test outputs; even the conditional
`nix flake check --no-build` is not a build of those outputs.

## Architecture

1. Every push to trusted `main`, regardless of changed paths, or a manual
   dispatch from `main`, starts the `Build and cache NixOS systems` workflow.
2. The persistent `nixos-sov` runner evaluates the current flake and obtains
   its host inventory from the flake-owned `machine-build-matrix` package.
   Installation media outputs whose names end in `Iso` are excluded.
3. For an ordinary push, the runner compares every current host's exact
   `config.system.build.toplevel.drvPath` at `github.event.before` and the exact
   pushed `github.sha`. The baseline is the previous revision in that push,
   not `HEAD^` and not the last successfully built revision. Only hosts whose
   derivation changed are placed in the serial build matrix. A shared input or
   module change can therefore select many or all hosts; a single-host build is
   not guaranteed.
4. The comparison still evaluates every current host. A current evaluation
   failure fails validation. A missing or inaccessible baseline, a baseline
   evaluation failure, or a newly added host that cannot be evaluated at the
   baseline produces a visible warning and safely falls back to the full
   current-host matrix. Manual dispatch also selects the full fleet.
5. The global `nix flake check --no-build` runs for manual and safety-fallback
   full-fleet runs. An ordinary successful selective comparison does not run
   that global check, so it does not validate other flake outputs, including
   installation media outputs. It still evaluates every current real-machine
   system derivation. If no host derivation changed, the matrix job is skipped
   before matrix expansion. Documentation-only pushes can therefore evaluate
   the fleet without building hosts, provided comparison succeeds and no host
   derivation changes; the full-fleet fallback still applies otherwise.
6. The runner builds each selected machine's
   `config.system.build.toplevel` one host at a time, with up to eight concurrent
   Nix build jobs. Outputs already in the Nix store or Attic cache avoid
   rebuilding as usual. The runner's Nix daemon still defaults each job to 28
   cores; concurrent jobs share its `2800%` CPU quota and existing memory limits.
7. After each successful build, `attic push nixos <output>` uploads the full
   output closure to `https://attic.basn.se/`. Attic's normal closure upload
   behavior skips paths already present in the cache.
8. Machines with the auto-upgrade role independently follow
   `git+https://github.com/basn/nixos` and run `nixos-upgrade.service` nightly.
   Each downloads matching paths from the `nixos` Attic cache and switches only
   after evaluation and realization succeed.

The workflow runs only trusted `main` code. Do not add `pull_request`,
`pull_request_target`, fork, or other untrusted-code triggers to the persistent
self-hosted runner.

## GitHub credentials

The workflow requires two GitHub Actions secrets:

- `NIX_GITHUB_TOKEN` for authenticated flake input access.
- `ATTIC_TOKEN` with pull/push access to the `nixos` cache.

Attic credentials are written under a run- and host-specific directory in
`RUNNER_TEMP` and deleted by an always-run cleanup step. Secret values must
never be printed or stored in the repository or Nix store.

No GitHub Actions SSH or activation credentials are required. After this
migration, the old `DEPLOY_SSH_KEY` and `DEPLOY_KNOWN_HOSTS` secrets and the
`ENABLE_AUTOMATIC_DEPLOY` repository variable can be deleted manually in
GitHub.

## Scheduling and failure behavior

Machines with the auto-upgrade role enable `system.autoUpgrade` at 02:00 in
their configured `Europe/Stockholm` timezone with a stable per-machine
randomized delay of up to four hours. The persistent timer catches up after downtime and still
applies the randomized delay. Automatic reboots are disabled.

CI is not a deployment gate: auto-upgrades run independently of workflow success.

The shared Nix configuration already trusts and uses
`https://attic.basn.se/nixos`. If a GitHub Actions host build or cache upload
fails, the workflow fails visibly and the fleet cache may not be ready for
that commit. Machines retain their current generation when their own
evaluation, download, build, or switch fails.

Because the automatic comparison baseline is the previous revision in the
push rather than the last successful cache run, a failed or incomplete cache
run is not automatically retried by a later unrelated selective push. Use a
manual dispatch from `main` to validate and repopulate the full fleet cache.

`modules/nixos-upgrade-notify.nix` keeps the existing Home Assistant success
and failure notifications attached to `nixos-upgrade.service`. A machine-side
failure is therefore reported independently of the GitHub Actions result.

Battlestation may require several hours when its CachyOS ThinLTO kernel and
matching ZFS module are absent from the private cache. The runner does not add
or trust the external CachyOS binary cache.
