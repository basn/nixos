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
