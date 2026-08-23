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
4. Create the GitHub Actions secret `DEPLOY_SSH_PRIVATE_KEY` from the private
   key corresponding to the `deploy` public key in
   `modules/deploy-rs-user.nix`. Do not place that private key in the runner
   checkout or in Nix configuration.
5. Create `DEPLOY_KNOWN_HOSTS` from independently verified host-key
   fingerprints for every deployment target. Do not use `accept-new` or
   disable host-key checking.
6. Protect GitHub `main`: require pull requests and checks, and block force
   pushes and branch deletion.
7. Never approve public fork code to run on the persistent runner.

## First deployment and rollout policy

The first live deploy-rs activation must target `nixos-sov2`, not `services`.
Verify its activation, post-deployment health checks, and rollback behavior
before relying on the automatic group. This workflow's automatic group includes
`services`, so do not merge or enable automatic main deployments until that
initial `nixos-sov2` proof has been completed through a separately authorized,
trusted operation.

`battlestation` and `laptop` are selected individually through
`workflow_dispatch`. `bandit` is separate infrastructure. `nixos-sov` is a
manual, isolated controller deployment and must be last; no other job may rely
on the runner while it activates.

Keep `system.autoUpgrade` enabled for now. Remove it only in a later change,
after deploy-rs has been proven live.
