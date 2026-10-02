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
- Local inference: CUDA-backed `llama-server` serves the Qwen3.5-9B Q8 model
  as `qwen3.5-9b-local` on TCP/8080.

## Local inference networking

`llama-server` listens on `0.0.0.0:8080`, and the host firewall permits
TCP/8080 on all interfaces. This deliberately makes the OpenAI-compatible API
available on Bandit's LAN and `wt0` addresses; there is no per-peer firewall
restriction in this repository. The surrounding perimeter firewall and the
user-managed NetBird policy are the access boundary.

qBittorrent remains available through the existing `rt.basn.se` Nginx route,
which connects directly to its VPN namespace. It has no host port mapping on
TCP/8080 because that would intercept traffic before `llama-server`.

Hermes uses `http://bandit.netbird.basn.se:8080/v1`, so that hostname must
resolve to Bandit's NetBird address and NetBird connectivity must already work
between the hosts. NetBird configuration is not managed here.

The server keeps `--ctx-size 131072 --parallel 2`. llama.cpp divides that
server context across the two slots, yielding 65,536 tokens per concurrent
slot. That is the configured serving allocation, not the model's training
context or a hardware limit. `--no-mmproj` keeps this endpoint text-only.

Host-specific service definitions live in `services/`; SOPS declarations are
in `sops.nix`. Keep storage and service changes local to this directory.

PinePods deployment, authentication, storage, and recovery requirements are
documented in [`../../docs/pinepods.md`](../../docs/pinepods.md).

## Swap

Bandit has a 64 GiB swap partition on the dedicated Intel SSDPEKKW256G7 with
serial `BTPY6325064Y256D`. The partition uses PARTUUID
`95419ba3-5534-4825-9705-13820aa59fc6`, priority 100, and NixOS random-key
encryption. NixOS opens the partition as plain dm-crypt with a new random key
and initializes swap on the encrypted mapper, so the underlying partition does
not contain persistent plaintext swap metadata. Previous swap contents become
inaccessible when that key is discarded; this is not a guarantee that the
physical flash cells are erased.

Only the first 64 GiB of the 256 GB SSD is partitioned; the remainder is left
unallocated. This swap is not suitable for hibernation because its encryption
key is regenerated. The old inactive `osdata/swap` 16 GiB zvol remains in place
until the new swap has been verified after a reboot, after which its removal is
a separate operation.

```sh
nix build .#nixosConfigurations.bandit.config.system.build.toplevel --no-link
```

Building only validates the declared system closure. It does not deploy the
configuration, open the live firewall, restart `llama-server`, or configure
NetBird.
