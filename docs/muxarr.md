# Muxarr

Muxarr 0.9.13 runs on `bandit` as a rootful Podman container. The image is
pinned by release tag and multi-architecture manifest digest in
`machines/bandit/services/muxarr.nix`; the digest was verified against GHCR on
2026-11-05 and identifies upstream commit
`7d1c6bb0609db0ca6a4b0e2e723a7a244562a916`.
GitHub confirmed 0.9.13 as the latest stable release on that date. GHCR's
reported digest matched a locally calculated SHA-256 of the version-tagged OCI
index, which includes linux/amd64 and linux/arm64; the amd64 image's revision
label matches the release commit.

## Upgrading to 0.9.13

The [0.9.13 release notes](https://github.com/KirovAir/muxarr/releases/tag/v0.9.13)
include a fix preventing filenames from executing shell commands during
post-processing, Dolby Vision preservation when ffmpeg rewrites MP4 files,
container-timezone timestamps, live conversion progress fixes, and updated
EF Core 10.0.13 and mkvtoolnix 103 dependencies that clear the reported
Cryptography.Xml advisories. Track selection now retains explicitly allowed
undetermined tracks and applies codec exclusions before the "only option"
checks; review profile previews on backed-up test files before resuming jobs.

The release also migrates conversion logs from the database's text column to a
separate table. Before an authorized deployment, take a consistent backup of
`/var/lib/muxarr` (including SQLite state and settings). Do not assume reverting
the image also reverts the schema; retain the pre-upgrade backup for rollback.
Conversions now check available space beside the source before writing a copy
and fail if reported free space is less than the source size. Verify this on
both ZFS and the rclone mount after deployment; a free-space check is not a
reservation or a replacement for the storage safeguards below.

The upstream Dockerfile and entrypoint retain port 8183, `/config`, and the
`PUID`/`PGID`/`UMASK` interface. This pin update does not change mounts, media
identity, ingress, or startup safeguards, and does not establish runtime
compatibility through a build alone.

## Container configuration

The container persists its SQLite database and settings in `/var/lib/muxarr`
on the host, mounted at `/config`. It receives the evaluated `plex` UID and GID
through upstream's `PUID` and `PGID` interface and uses `UMASK=002`. The media
mounts are writable and retain identical host and container paths:

- `/data/files:/data/files`
- `/mnt/telia:/mnt/telia`

There is no `:U` remapping, privileged mode, Docker socket, or recursive media
ownership change. The upstream entrypoint adjusts ownership only under
`/config` before dropping to the configured media identity.

## Storage safeguards

Muxarr can replace media files after remuxing, so its startup is gated on the
expected media mounts. `podman-muxarr.service` requires the `/data/files` ZFS
mount and `rclone.service`. Before every container start it verifies that
`/data/files` is a ZFS mount and that `/mnt/telia` is the expected
`encrypted:/files/` `fuse.rclone` mount. A failed check prevents that startup
attempt.

The container unit is ordered after and requires `rclone.service`, is part of
rclone, and is bound to both rclone and the `/data/files` mount unit. An explicit
`systemctl restart rclone.service` therefore stops Muxarr before rclone unmounts,
then starts a fresh container after rclone reports that the replacement mount is
ready. These relationships also stop Muxarr when rclone exits or the ZFS mount
unit disappears.

This does not automatically reactivate Muxarr after an unexpected rclone crash
and automatic rclone recovery, or after separate `stop` and `start` commands.
It also does not detect an active but hung rclone process or a Telia FUSE mount
that detaches while rclone remains active. In those cases Muxarr may remain
stopped or attached to the old mount. After confirming that rclone is active and
`/mnt/telia` has the expected identity, manually restart Muxarr:

```sh
systemctl is-active rclone.service
findmnt --mountpoint /mnt/telia --types fuse.rclone --source encrypted:/files/
sudo systemctl restart podman-muxarr.service
```

A live restart and mount inspection require explicit operational authorization
and are not performed by this repository change. Stopping the container for an
rclone restart can interrupt an active conversion or upload; inspect Muxarr's
queue and output before retrying work, because partial work may need manual
recovery.

The startup checks and Podman's bind-mount creation are not atomic. A mount can
change after the checks or while Podman performs work such as an image pull.
They prevent startup when an expected mount is absent at check time, but they do
not monitor a running container, guarantee detection of an outage, or protect an
ongoing remux from storage failure.

The rclone mount uses `--jottacloud-hard-delete`. Muxarr processing is
destructive from the remote storage provider's perspective: successful remuxes
replace source files, and deleted or replaced remote objects may not be
recoverable from provider trash. The application's output validation reduces
the chance of replacing a source with an invalid result, but it is not a backup.
Ensure tested snapshots or independent backups exist before processing either
library.

## Ingress and authentication

Muxarr publishes port 8183 only on Bandit's loopback address. Bandit's nginx
accepts the `muxarr.basn.se` virtual host only from the `services` host at
`10.1.1.8/32`, then proxies to `127.0.0.1:8183`. The `services` nginx terminates
TLS at `https://muxarr.basn.se`, enables WebSocket proxying for Blazor, and uses
strict Authentik forward authentication on `/`.

Unlike the existing Sonarr route, Muxarr has no LAN-address bypass. Every UI,
API, and WebSocket request goes through Authentik; there is deliberately no API
or authentication-path exception. Muxarr's own optional login is defense in
depth rather than a replacement for the ingress policy.

## Manual prerequisites

The repository does not provision an Authentik forward-auth application for
Muxarr and does not manage public DNS. Before an explicitly authorized
deployment:

1. Create the `muxarr.basn.se` DNS record pointing to the same public ingress as
   the other `services` nginx sites.
2. In Authentik, verify whether the existing domain-level forward-auth Proxy
   Provider already covers `https://muxarr.basn.se`. If it does, add or verify an
   Authentik application for Muxarr and ensure that provider is assigned to the
   embedded outpost. If it does not, create a domain-level forward-auth Proxy
   Provider with external host `https://muxarr.basn.se`, attach it to a Muxarr
   application with the intended user/group policy, and assign it to the
   embedded outpost. Do not use single-application mode or enable an
   unauthenticated nginx bypass.
3. Confirm the embedded outpost serves
   `/outpost.goauthentik.io/auth/nginx` for this hostname and test both an
   authorized session and a denied user. An nginx vhost alone does not provision
   the Authentik provider, application, outpost assignment, or policy.
4. Verify routing preserves `10.1.1.8` as the source from `services` to Bandit.
   If routing introduces source NAT, replace Bandit's allowlist with the verified
   single ingress address rather than broadening it to a subnet.
5. Build both affected host outputs, then deploy only with explicit approval.

## Initial setup

Do not configure automatic library processing during initial setup. First set a
strong local Muxarr password, connect Sonarr or Radarr only if needed for
metadata lookup, add one narrowly scoped directory, scan it, and inspect dry-run
or preview results. Process backed-up test files before expanding scope. Enable
webhooks, automatic queueing, whole-library jobs, or broader directories only
after path mappings and language/track rules have been verified.

Use the same paths when configuring libraries and Sonarr/Radarr mappings:
`/data/files` and `/mnt/telia`. Changing them inside the container can break
path matching and weakens the ability to reason about which files will be
modified.

## Validation limits

A NixOS toplevel build validates module evaluation, generated systemd units,
nginx syntax, and store paths. It does not pull or start the OCI image, request
a TLS certificate, provision Authentik or DNS, verify live mount identities, or
exercise remuxing. Runtime checks require an explicitly authorized deployment
and should include the documented manual restart after a Telia remount, denied
and allowed authentication, Blazor reconnects, persistence across restart, and
a backed-up test remux on each storage backend.
