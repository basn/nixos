# Bandit

Flake output: `bandit`.

Bandit is the storage, media, and automation host. It uses ZFS and runs Plex,
Jellyfin, Sonarr, Radarr, Prowlarr, Muxarr, qBittorrent behind VPN confinement,
Unpackerr, Immich, PinePods, Attic, rclone, and Nginx.

## Configured services

- Media and automation: Plex, Jellyfin, Sonarr, Radarr, Prowlarr, Muxarr,
  Unpackerr, and qBittorrent in a WireGuard-constrained network namespace.
- Storage and applications: Attic, Immich, PinePods, rclone, ZFS scrubs, and
  Nginx. TypeType's seven containers run here after the authorized migration;
  see [`../../docs/typetype.md`](../../docs/typetype.md) for validation and the
  temporary auto-upgrade pause.
- Automation: ESPHome Device Builder and the host chassis-fan service.
- Local inference: CUDA-backed `llama-server` serves Gemma 4 12B IT Q8_0
  (`unsloth/gemma-4-12b-it-GGUF`, `gemma-4-12b-it-Q8_0.gguf`)
  as `gemma-4-12b-local` on TCP/8080.

## ESPHome Device Builder

`podman-esphome.service` starts the official, digest-pinned ESPHome image at
boot. Podman publishes the dashboard only on Bandit's `127.0.0.1:6052` and
`192.168.180.10:6052`, without adding a global firewall rule or Nginx route.
Use <http://192.168.180.10:6052/> only from the trusted LAN: it is plain HTTP
with no login, and anyone who can reach the address can use the dashboard.
Do not forward this port to untrusted networks.

For encrypted access, use your usual Bandit SSH account and hostname:

```sh
ssh -NT -o ExitOnForwardFailure=yes -L 127.0.0.1:6052:127.0.0.1:6052 bandit
```

Keep the tunnel running and open <http://127.0.0.1:6052/>. Processes running
on Bandit can also reach the loopback address directly.

Device YAML and `secrets.yaml` live in the container's `/config`, backed by
root-owned `/var/lib/esphome` (mode `0700`). Back it up privately before image
upgrades. The container has no USB passthrough: flash new devices over USB
from your workstation, then use OTA from the dashboard. The Podman bridge
does not provide LAN mDNS discovery; use a reachable IP in `use_address` (or
`manual_ip`) for OTA if `.local` resolution fails.

After deployment, `systemctl is-active podman-esphome` should report `active`
and `sudo podman port esphome 6052/tcp` should report only `127.0.0.1:6052`
and `192.168.180.10:6052`.

### Remote build receiver

Device Builder 1.28.1 uses TCP 6055 for its Noise WebSocket peer link. Podman
publishes it only at `192.168.180.10:6055`; this is not another dashboard
port. The Build Server setting is enabled by default in the standalone image.
Keep both ports on trusted networks, and approve pairing in Device Builder
only after verifying the peer's identity. No firewall rule is managed here.
`sudo podman port esphome 6055/tcp` should report only `192.168.180.10:6055`.

## Local inference networking

`llama-server` listens on `0.0.0.0:8080`, and the host firewall permits
TCP/8080 on all interfaces. This deliberately makes the OpenAI-compatible API
available on Bandit's LAN and `wt0` addresses; there is no per-peer firewall
restriction in this repository. The surrounding perimeter firewall and the
user-managed NetBird policy are the access boundary.

qBittorrent remains available through the existing `rt.basn.se` Nginx route,
which connects directly to its VPN namespace. It has no host port mapping on
TCP/8080 because that would intercept traffic before `llama-server`.

Clients using `http://bandit.netbird.basn.se:8080/v1` need that hostname to
resolve to Bandit's NetBird address and working NetBird connectivity.
NetBird configuration is not managed here. Hermes's declared routes, including
Jared, use OpenAI Codex instead; this local server remains available unchanged.

After deploying the model switch, remaining local clients must change their
model name from `qwen3.5-9b-local` to `gemma-4-12b-local`; the API URL is unchanged.

The server keeps `--ctx-size 131072 --parallel 2`. llama.cpp divides that
server context across the two slots, yielding 65,536 tokens per concurrent
slot. That is the configured serving allocation, not the model's training
context or a hardware limit. `--no-mmproj` keeps this endpoint text-only.

Host-specific service definitions live in `services/`; SOPS declarations are
in `sops.nix`. Keep storage and service changes local to this directory.

PinePods deployment, authentication, storage, and recovery requirements are
documented in [`../../docs/pinepods.md`](../../docs/pinepods.md).
Muxarr deployment, mount safeguards, authentication, and cautious initial setup
are documented in [`../../docs/muxarr.md`](../../docs/muxarr.md).

## rclone mount cleanup

When `rclone.service` stops, it first attempts the normal FUSE unmount of
`/mnt/telia`. After the rclone process has exited, a guarded post-stop step
reads the kernel mount table without traversing the mountpoint. It lazily
detaches the mount only when exactly one `/mnt/telia` entry remains and its
source and type are `encrypted:/files/` and `fuse.rclone`. An absent mount is
successful; mount-table read errors, stacked mounts, unexpected identities,
and detach or verification failures fail visibly without touching an
unverified mount.

The lazy detach is crash recovery for the stale kernel mount. It neither
deletes `/data2/rclone-cache` nor guarantees that pending cached uploads were
flushed before rclone exited. The focused mock check is available as:

```sh
nix build .#nixosConfigurations.bandit.config.system.build.rcloneCleanupMountTest --no-link
```

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
