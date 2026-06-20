# Agent Guidance

This repository is a personal multi-host NixOS flake. Work conservatively:
identify the affected host, keep changes narrowly scoped, validate them, and
separate repository changes from live-machine operations.

## Repository Layout

- `flake.nix` defines the supported `nixosConfigurations` and their inputs.
- `common/` contains configuration shared by most hosts.
- `modules/` contains reusable local NixOS modules.
- `machines/<host>/` contains host-specific configuration and services.
- `hjem/` contains the optional user environment for desktop hosts.
- `secrets/` and `machines/*/secrets/` contain SOPS-managed material.

Treat `flake.nix` as the source of truth for host names. Do not maintain a
second hard-coded host inventory in documentation.

## Working Rules

- Inspect the relevant imports and options before editing.
- Use `rg` or `rg --files` for repository searches.
- Use `apply_patch` for deliberate file edits.
- Preserve existing dirty-worktree changes; they belong to the user unless
  proven otherwise.
- Never revert unrelated changes or use destructive Git commands.
- Keep hardware, interface, filesystem, and service settings scoped to the
  affected host.
- Do not casually edit generated `hardware-configuration.nix` files.
- Prefer existing repository patterns over introducing a new abstraction for
  a one-host change.
- Prefer public service hostnames in application configuration unless an
  internal endpoint is explicitly required.

## Authorization Boundaries

- Troubleshooting permits read-only local and remote inspection.
- Read-only SSH diagnostics are allowed by default.
- A request to fix or implement permits repository edits and validation.
- Repository edits do not authorize deploying them to a live host.
- Require an explicit request before:
  - running `nixos-rebuild switch` against a remote machine;
  - restarting, stopping, enabling, or disabling live services;
  - rebooting or shutting down a machine;
  - changing live networking, firewall, storage, or authentication state;
  - committing, pushing, or opening a pull request;
  - updating `flake.lock` or changing flake inputs.
- Do not disable authentication, TLS, firewalls, or other safety controls just
  to make a test pass.

## Secrets

- Never print, copy into chat, log, or commit plaintext secret values.
- Do not decrypt SOPS files merely to inspect their contents.
- Refer to secrets by their configured file path or SOPS attribute.
- Avoid commands that dump complete environments, service definitions, or
  state files when they may contain credentials.
- If validation needs a secret, verify its presence, ownership, permissions,
  or key name without displaying its value.
- New persistent secrets must follow `.sops.yaml` creation rules and existing
  host-specific SOPS patterns.

## Troubleshooting Tools

Do not permanently install a utility merely because it is missing during
diagnostics. Use an ephemeral Nix environment.

From this repository, prefer its locked inputs:

```sh
nix shell --inputs-from . nixpkgs#pciutils -c lspci -nnk
nix shell --inputs-from . nixpkgs#usbutils -c lsusb -t
nix shell --inputs-from . nixpkgs#nvme-cli -c nvme smart-log /dev/nvme0
nix shell --inputs-from . nixpkgs#smartmontools -c smartctl -a /dev/sda
```

On a remote host without a checkout, use the host's configured registry:

```sh
nix run nixpkgs#pciutils -- -nnk
nix shell nixpkgs#usbutils -c lsusb -t
```

- Prefer `nix run nixpkgs#<package> -- <args>` when the package exposes the
  desired executable as its default program.
- Prefer `nix shell nixpkgs#<package> -c <command>` when package and command
  names differ.
- Use `sudo` only for the individual read-only command that requires it.
- Do not add diagnostic packages to `environment.systemPackages` unless the
  user explicitly wants them permanently available.
- Do not execute untrusted or arbitrary third-party flakes for diagnostics.
- When a remote login shell is Fish, use `bash -lc` for Bash-only loops,
  assignments, or compound commands.

## Validation

Validate in proportion to the change and begin with the narrowest affected
output.

For edited Nix files:

```sh
nixfmt --check path/to/file.nix
git diff --check
```

For a host configuration:

```sh
nix build .#nixosConfigurations.<host>.config.system.build.toplevel --no-link
```

For installation media:

```sh
nix build .#nixosConfigurations.<iso>.config.system.build.isoImage --no-link
```

- Build every affected host when changing `common/`, a shared module,
  `flake.nix`, or `flake.lock`.
- Do not build all hosts for a change isolated to one machine.
- Do not run formatters in rewrite mode across unrelated files.
- Report any skipped or failed validation clearly.

## Authorized Deployment

Before a requested remote switch:

- Confirm the target flake output and SSH destination.
- Check `systemctl status nixos-upgrade.service` and related timers. Several
  hosts auto-upgrade from `github:basn/nixos`, which can race and revert a
  local deployment.
- Build successfully before switching.
- Avoid combining unrelated host changes in one deployment.

After switching:

- Confirm `/run/current-system` points to the intended generation.
- Check the relevant units with `systemctl is-active` and `systemctl --failed`.
- Verify the affected endpoint, interface, mount, or application behavior.
- Review focused recent logs rather than dumping the complete journal.
- Never expose secret values while verifying generated environment files.

## Completion Report

State what changed, which host outputs were validated, and whether anything
was deployed. Mention remaining warnings or manual actions. Use clickable file
paths where useful, and do not claim a live fix when only the repository was
changed.
