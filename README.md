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
The Home Assistant and NixOS MCP launchers use the locked
`nixpkgs-unstable-small` input from the checkout at `/home/basn/nixos`, regardless
of OpenCode's working directory; keep that checkout available at this path.

## Flake Outputs

`flake.nix` is the authoritative inventory of NixOS hosts and installation
media. Inspect the outputs with:

```sh
nix flake show .
```

Build a host or installation image without creating a `result` symlink:

```sh
nix build .#nixosConfigurations.<host>.config.system.build.toplevel --no-link
nix build .#nixosConfigurations.<iso>.config.system.build.isoImage --no-link
```

Each active host directory under `machines/` includes a README describing its
role, configured services, primary configuration files, and matching build
command. The Cygate directories document their `nixos-sov` output names.

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
