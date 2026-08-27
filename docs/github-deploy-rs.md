# Trusted GitHub Actions deployment

The repository is public. The persistent `nixos-sov` runner must execute only
trusted `main` commits or explicit dispatches by repository collaborators. Do
not add `pull_request`, `pull_request_target`, fork, or other untrusted-code
triggers to the deployment workflow.

## Human-only prerequisites

1. Activate the merged `nixos-sov` configuration through the existing trusted
   deployment method.
2. Confirm `github-runner-nixos-sov.service` is active.
3. In GitHub **Settings -> Actions -> Runners**, confirm `nixos-sov` is online
   with `self-hosted`, `nixos`, and `nix-nightly` labels.
4. Create the GitHub Actions secret `DEPLOY_SSH_KEY` from the private
   key corresponding to the `deploy` public key in
   `modules/deploy-rs-user.nix`. Do not place that private key in the runner
   checkout or in Nix configuration.
5. Create `DEPLOY_KNOWN_HOSTS` from independently verified host-key
   fingerprints for every deployment target. Do not use `accept-new` or
   disable host-key checking.
6. Protect GitHub `main`: require pull requests and checks, and block force
   pushes and branch deletion.
7. Never approve public fork code to run on the persistent runner.
8. Create an `ATTIC_TOKEN` Actions secret with only pull/push access to the
   `nixos` cache at `https://attic.basn.se/`. Its value is supplied only to
   trusted selected-target build jobs; never put it in the repository or Nix
   configuration.

## Validation, builds, and cache population

The ordinary validation job evaluates the flake with `nix flake check
--no-build --show-trace`. This deliberately evaluates checks without realizing
every deploy-rs activation closure. The warning `unknown flake output 'deploy'`
is expected: deploy-rs consumes that output even though it is not a standard
flake output.

The validation job also builds the deploy-rs schema check. Full
`deploy-activate` validation realizes every deployment profile and is therefore
intentionally separate from ordinary push CI; run it only in a specifically
scheduled or manually approved, longer-running workflow.

After evaluation, the workflow selects only the deployment targets for its
scope and runs one serialized build/cache job for each target. Automatic pushes
build `vault`, `services`, `hermes`, `netbird`, `nixos-sov2`, `skullcanyon`, and
`lenovo`; they never build Battlestation. Manual scopes build only their single
selected target. Each job builds the corresponding `deploy-<host>` package,
which is the exact deploy-rs system activation closure, then pushes that output
to the private `nixos` Attic cache only after the build succeeds.

The first source build, notably Battlestation's pinned CachyOS ThinLTO kernel
and ZFS module, can take several hours. Later matching builds should use the
Attic cache. The manual Battlestation job has a six-hour timeout; ordinary
automatic-host jobs have shorter per-host limits, so a slow host cannot consume
one shared validation timeout.

`nixos-sov` installs `attic-client` and constrains the actual Nix daemon to one
job, eight build cores, 800% CPU, idle I/O priority, and 22/26 GiB soft/hard
memory limits. These limits apply to Nix build subprocesses without adding or
trusting the external CachyOS binary cache.

## First deployment and rollout policy

Follow this sequence exactly:

1. Keep the repository variable `ENABLE_AUTOMATIC_DEPLOY` unset or set to
   `false`. Only the exact value `true` enables automatic deployment from a
   push to `main`; pushes always validate and build regardless.
2. Merge the workflow to `main`.
3. Confirm that the resulting push validates and builds successfully while
   deployment is skipped. There is no validation-only manual dispatch.
4. Dispatch the workflow from `main` with the `nixos-sov2` scope. A dispatch
   selects a deployment target only; it cannot select another source revision.
5. Verify activation, post-deployment health, deploy-rs magic rollback, and an
   explicit rollback before expanding the rollout.
6. Only after that proof succeeds, set `ENABLE_AUTOMATIC_DEPLOY=true`.
7. Deploy `nixos-sov` separately through the existing trusted external method,
   and always last. It is the GitHub runner/controller, so this workflow never
   deploys it; self-deployment could terminate the job before deploy-rs
   confirms magic rollback and before credential cleanup. A future deployment
   path needs a separate trusted controller.

`battlestation`, `laptop`, and `bandit` are also selected individually through
main-only `workflow_dispatch`. Keep `system.autoUpgrade` enabled until
deploy-rs has been proven live.
