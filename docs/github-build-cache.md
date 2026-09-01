# GitHub build cache and nightly upgrades

The repository uses a build-and-cache model. GitHub Actions never connects to
machines over SSH and never activates a NixOS configuration.

## Architecture

1. A push to trusted `main`, or a manual dispatch from `main`, starts the
   `Build and cache NixOS systems` workflow.
2. The persistent `nixos-sov` runner evaluates the flake and obtains its build
   matrix from the flake-owned `machine-build-matrix` package. Installation
   media outputs whose names end in `Iso` are excluded.
3. The runner builds every real machine's
   `config.system.build.toplevel` serially with one Nix job and eight cores.
4. After each successful build, `attic push nixos <output>` uploads the full
   output closure to `https://attic.basn.se/`. Attic's normal closure upload
   behavior skips paths already present in the cache.
5. Each machine independently follows `git+https://github.com/basn/nixos` and
   runs `nixos-upgrade.service` nightly. It downloads matching paths from the
   `nixos` Attic cache and switches only after evaluation and realization
   succeed.

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

All real machines enable `system.autoUpgrade` at 02:00 in their configured
`Europe/Stockholm` timezone with a stable per-machine randomized delay of up
to four hours. The persistent timer catches up after downtime and still
applies the randomized delay. Automatic reboots are disabled.

The shared Nix configuration already trusts and uses
`https://attic.basn.se/nixos`. If a GitHub Actions host build or cache upload
fails, the workflow fails visibly and the fleet cache may not be ready for
that commit. Machines retain their current generation when their own
evaluation, download, build, or switch fails.

`modules/nixos-upgrade-notify.nix` keeps the existing Home Assistant success
and failure notifications attached to `nixos-upgrade.service`. A machine-side
failure is therefore reported independently of the GitHub Actions result.

Battlestation may require several hours when its CachyOS ThinLTO kernel and
matching ZFS module are absent from the private cache. The runner does not add
or trust the external CachyOS binary cache.
