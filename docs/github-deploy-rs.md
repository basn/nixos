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
