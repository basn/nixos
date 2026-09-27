# Bandit

Flake output: `bandit`.

Bandit is the storage, media, and automation host. It uses ZFS and runs Plex,
Jellyfin, Sonarr, Radarr, Prowlarr, qBittorrent behind VPN confinement,
Unpackerr, Immich, PinePods, Attic, rclone, and Nginx.

## Configured services

- Media and automation: Plex, Jellyfin, Sonarr, Radarr, Prowlarr, Unpackerr,
  and qBittorrent in a WireGuard-constrained network namespace.
- Storage and applications: Attic, Immich, PinePods, rclone, ZFS scrubs, and
  Nginx.
- Automation: the host chassis-fan service.

Host-specific service definitions live in `services/`; SOPS declarations are
in `sops.nix`. Keep storage and service changes local to this directory.

PinePods deployment, authentication, storage, and recovery requirements are
documented in [`../../docs/pinepods.md`](../../docs/pinepods.md).

```sh
nix build .#nixosConfigurations.bandit.config.system.build.toplevel --no-link
```
