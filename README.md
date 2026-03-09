# NixOS Flake

Personal NixOS flake for multiple machines and install media.

## What Is In This Repo

- Multi-host NixOS flake in `flake.nix`
- Shared modules in `common/`
- Host-specific configs in `machines/`
- Optional user environment via `hjem/`

## Hosts

Current `nixosConfigurations`:

- `bandit`
- `vault`
- `laptop`
- `battlestation`
- `services`
- `nixos-sov`
- `nixos-sov2`
- `netbird`
- `skullcanyon`
- `lenovo`
- `minimalIso`
- `graphicalIso`

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
