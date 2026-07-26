# NixOS Flake

Personal NixOS flake for multiple machines and install media.

## What Is In This Repo

- Multi-host NixOS flake in `flake.nix`
- Shared modules in `common/`
- Host-specific configs in `machines/`
- Optional user environment via `hjem/`
- Per-host role and service documentation in `machines/<host>/README.md`

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
