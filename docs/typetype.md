# TypeType on Bandit

**Live migration performed with explicit authorization on 2026-11-08.**
Runtime/data/security checks passed; the user subsequently confirmed authenticated
application functionality works. See the execution record below. This migration does not repoint
auto-upgrades or upgrade images. Both hosts' auto-upgrades remain paused.
Do not independently deploy the old configuration or initialize an empty
destination. The following preparation/checklist sections describe the plan.

## Prepared topology

- Bandit owns the seven pinned TypeType containers: web, server, token,
  downloader, PostgreSQL, Dragonfly, and Garage. Image versions, internal
  ports, and the public origin `https://tube.basn.se` are unchanged.
- Services retains public TLS and strict Authentik authentication, forwarding
  incoming application `Authorization` (not Authentik's replacement token).
  It relays to `http://192.168.180.10:80` with the original Host.
- Bandit's `tube.basn.se` relay allows only `10.1.1.8/32`, denies all other
  clients, and forwards to loopback `127.0.0.1:18082`. Forwarded identity,
  scheme, host, and Authorization headers are preserved, with WebSockets,
  300-second proxy timeouts, disabled response buffering, and a 2 GiB upload
  limit on the relay. No firewall changes are included.
- `machines/bandit/secrets/typetype.env` is rewrapped for basn and Bandit,
  not Services. Payload ciphertext is unchanged; no secret rotation is intended.
- No TypeType refresh hook or new Bandit refresh service/timer is included.
  Services' existing network-optimizer refresh implementation is unchanged.

## Repository update — TypeType 1.17.0

Bandit's four application images are pinned together to 1.17.0 with verified
GHCR digests and Linux/amd64 availability. Supporting images are unchanged.
The local nginx template now relays `/streams/`, `/proxy`, and `/proxy/`, matching
the upstream 1.17.0 template: server-generated manifest and proxy URLs use these
root-level paths as well as `/api/`. Remote login remains disabled, and the
downloader still requires the existing `S3_ACCESS_KEY`/`S3_SECRET_KEY` aliases.
This repository update does not deploy or establish live application behavior.

## Storage prerequisite (performed during cutover)

Create a single `data/typetype` ZFS dataset with **inherited encryption** and
`mountpoint=legacy`, mounted at `/data/typetype`. Separately verify that its
encryption is enabled, its encryption root is the intended parent, and its
key is available. Do not create child datasets: `postgres`, `garage-meta`,
and `garage-data` are ordinary directories within that parent dataset.

The declaration alone neither creates nor encrypts a dataset. The storage
service requires the mount and checks the exact `findmnt` identity
`data/typetype zfs` at `/data/typetype` before creating directories. Missing,
wrong, stacked, or unreadable mounts fail closed. Both persistent containers
also require the storage service and mount, repeat the guard before startup,
and bind their lifetime to the mount. The identity guard does not verify ZFS
encryption properties; those must be checked before cutover.

| Source retained on Services | Destination on Bandit | Owner/mode |
| --- | --- | --- |
| `/docker/typetype` | `/data/typetype` | root:root 0750 |
| `/docker/typetype/postgres` | `/data/typetype/postgres` | 999:0 0700 |
| `/docker/typetype/garage-meta` | `/data/typetype/garage-meta` | root:root 0750 |
| `/docker/typetype/garage-data` | `/data/typetype/garage-data` | root:root 0750 |

Preparation sets only directory-root permissions, without recursive chown or
Podman's `:U` relabeling of ownership. A later copy must preserve numeric
ownership, permissions, and PostgreSQL/Garage contents consistently.

## Network verification

Read-only checks on Bandit on 2026-11-08 inspected all IPv4 route tables,
policy rules, and all rootful Podman network subnets. Existing networks were
`10.88.0.0/16` and PinePods' `10.92.0.0/24`; host routes to both `10.89.0.1`
and the proposed `10.90.0.1` made those candidates unsuitable.
`10.91.0.0/24` had no conflicting non-default route or Podman subnet, so
TypeType uses that subnet and gateway/DNS resolver `10.91.0.1` together.
Only the standard local/main/default policy rules were present.

Recheck immediately before cutover. `podman network create --ignore` does
**not** validate a preexisting `typetype` network: inspect its subnet, gateway,
and DNS configuration before allowing startup. No network was created during
repository preparation.

## Separately authorized cutover checklist

1. Finalize a recoverable backup and verify recovery before changing live
   services. **Ongoing backup destination and retention remain unresolved**;
   this change does not introduce a backup system. An old snapshot alone
   does not guarantee a current or application-consistent recovery point.
2. Coordinate both hosts' auto-upgrades and Services' container refresh/prune
   timers so they cannot restart writers or revert the migration. Inspect
   actual unit/timer state before deciding which operations are needed.
   Timer/service changes require separate authorization.
3. Create and verify the encrypted destination dataset, mount identity,
   recipient availability, network, and relay connectivity. Do not start
   destination containers against an empty dataset.
4. Quiesce ingress and stop **all TypeType writers**, including PostgreSQL
   and Garage. Take a consistent cold copy of all three directories as one
   migration set, preserving numeric ownership and permissions. Do not copy
   a running database or Garage metadata independently of its object data.
   Dragonfly queue state is not persisted or migrated; drain or explicitly
   accept losing queued/in-flight jobs before stopping writers.
5. Verify the copy and backup, then coordinate deployment of both prepared
   host outputs and startup. Keep the original source directories untouched
   for rollback. Reconfirm `/run/current-system`, relevant units, failed units,
   mount identity, and focused recent logs without displaying secret values.
6. Verify public TLS; unauthenticated rejection/redirect; authenticated login;
   application Authorization forwarding; playback and seek/range requests;
   download enqueue/completion/retrieval; WebSockets where used; and denial
   of direct relay access from unauthorized clients. Cut over only after
   those checks pass. Repository builds cannot establish these live results.

Rollback needs coordinated ingress/service changes. Once Bandit accepts new
writes, simply restarting the old source loses those writes: reconcile them
or explicitly accept that loss before rollback. Never run both writer sets.

## Repository checks

```sh
bash machines/bandit/services/typetype-storage-guard-test.sh machines/bandit/services/typetype-storage-guard.sh
nix build .#nixosConfigurations.bandit.config.system.build.typetypeStorageGuardTest --no-link --no-update-lock-file
nix build .#nixosConfigurations.bandit.config.system.build.typetypeDownloaderEnvTest --no-link --no-update-lock-file
nixfmt --check machines/bandit/configuration.nix machines/bandit/sops.nix machines/bandit/services/typetype.nix machines/bandit/services/nginx.nix machines/services/configuration.nix machines/services/sops.nix machines/services/services/nginx.nix
git diff --check
nix build .#nixosConfigurations.bandit.config.system.build.toplevel --no-link --no-update-lock-file
nix build .#nixosConfigurations.services.config.system.build.toplevel --no-link --no-update-lock-file
```

These commands build/test only; they do not deploy, copy data, create datasets,
change live timers, or authorize the final migration.

## Execution record — 2026-11-08 UTC

- Identity confirmed over strict, existing SSH trust: `basn@services` reported
  `services`; `basn@bandit` reported `bandit`. No host-key bypass was used.
- 16:17: both inactive upgrade services and active/waiting upgrade timers
  were persistently masked before deployment. See restoration below.
- Bandit: created `data/typetype`, `mountpoint=legacy`, mounted at
  `/data/typetype`; verified AES-256-GCM, encryption root `data`, key available.
  Created `typetype` network after rechecking routes/subnets:
  `10.91.0.0/24`, gateway/resolver `10.91.0.1`, DNS enabled.
- 16:19: stopped source web, server, downloader and token before storage;
  Redis had zero queue entries and zero keys after writers stopped. Stopped
  PostgreSQL, Garage and Dragonfly, and temporarily runtime-masked all seven
  source units. No queued jobs needed discarding.
- Created one cold archive containing `postgres`, `garage-meta`, `garage-data`
  with numeric owners/modes. Streamed it through two strictly verified SSH
  connections, without a local plaintext intermediate. Verified archive hash
  and `tar --compare` against source and restored destination before startup.
- Took `data/typetype@migration-cold-20261108T1615Z` before destination startup.
- 16:20: first Bandit switch; 16:22: scoped follow-up downloader fix deployed;
  16:23: Services switched to the Bandit relay. Source TypeType units are absent
  from its deployed configuration; temporary source-unit masks were removed.
  Original source directories remain identical to the cold archive.

### Deployed outputs and checks

Both outputs were rebuilt with `--no-update-lock-file`, copied with `nix copy`,
set as the remote system profiles, and activated via their exact
`bin/switch-to-configuration switch`. Both `/run/current-system` and the system
profile match:

```text
bandit:   /nix/store/fid8z650n8m6ak5fvbdblivgjhdhlx3d-nixos-system-bandit-26.05.20261106.57f1c89
services: /nix/store/15jih2kfqj2lv6mgf92a596x0k3xfjfi-nixos-system-services-26.05.20261106.57f1c89
```

- All seven containers running on Bandit, zero container restarts; none running
  on Services. Images do not configure container healthchecks, so this is not
  a claim of Podman `healthy` status. Neither host has failed systemd units.
- PostgreSQL 17.11 accepts connections. Exact per-public-table row counts in
  both databases match the stopped source (51 tables and one table respectively).
  Garage node-identity hashes match; Garage status succeeds. Dragonfly PONG,
  zero keys. Authenticated, SigV4-signed Garage bucket HEAD returns 200 without
  disclosing credentials or listing user objects.
- Bandit's SOPS deployment decrypts successfully using its recipient identity;
  `/run/secrets/typetype` is root-owned 0400. Runtime validation uncovered an
  inherited configuration bug: the pinned sops-nix ignores dotenv `key`
  selection, making S3 templates contain entire environment files. Removed
  those duplicate secret declarations/templates; downloader pre-start now
  generates only the two aliases in root-only `/run/typetype-downloader/s3.env`
  (directory 0700, file 0600). Missing/duplicate-key and output/permissions
  tests pass. Running downloader aliases match the intended keys; no rotation.
- Storage identity and all directory-root owners/modes match the table above.
  Web and all five version endpoints return 200 locally. Services-to-Bandit
  relay returns 200. Container ingress is bound only to `127.0.0.1:18082`.
- Public HTTPS validates TLS and returns Authentik 302 redirects for root/API
  paths, including an invalid bearer token; HTTP redirects to HTTPS.
  Unauthorized direct Bandit ingress, including spoofed forwarding headers,
  returns 403. No authentication, TLS or firewall controls were disabled.
- Both nginx configurations pass `nginx -t`. Authentik, PinePods and Muxarr
  units are active; existing public auth/pods/muxarr endpoints respond without
  gateway failures; existing pods/muxarr Bandit relays return 200.
- Bandit's first activation restarted the ZFS import oneshot because its
  ordering gained the TypeType mount. Despite having no export/stop command,
  its existing dependencies briefly remounted `/data/files` and restarted
  Muxarr. Both mounts and Muxarr recovered and were checked. Services' SSH
  restart trigger changed because Hermes' generated health list lost the
  TypeType containers; SSH policy did not change and SSH remained accessible.
- Focused recent server/downloader/Garage logs had zero lines matching
  error/exception/fatal/panic. Format checks, both scoped build tests and
  `git diff --check` pass. No commits, pushes, input/lock changes or reboot.

After these checks, the user reported that authenticated application functionality
works at `https://tube.basn.se` and authorized publication and merge to main.
This is manual user confirmation, not exhaustive automated coverage of
Authorization forwarding, playback/seek/range, WebSockets, or the download lifecycle.
No authorized application session was available to the agent; no jobs or writes
were manufactured to bypass this.

### Recovery material retained

```text
Services original: /docker/typetype
Services archive:  /docker/.typetype-migration-backup/20261108T1615Z/typetype-cold.tar
Bandit archive:    /data/typetype/.migration-backup/typetype-cold-20261108T1615Z.tar
Bandit snapshot:   data/typetype@migration-cold-20261108T1615Z
Archive bytes:     85288960
SHA-256:           12c6b082a5a988376cd41c374b587c335c57de7ee780437ebca065153fc94d40
```

Both archives are root-owned 0600 inside root-only 0700 directories. Source
storage/archive remain unencrypted, as before; Bandit's archive is encrypted
at rest. Both archives were verified; the restored databases actually started
and matched source table counts. These are cutover recovery points, not ongoing
backups. Ongoing backup destination/retention is still unresolved.

Each host retains root-only `/var/lib/typetype-migration/20261108T1615Z/` with
prior automation/system state, table counts, Garage identity hash, and protected
switch logs. Local build logs/output paths are under `/tmp/opencode/typetype-*`.
Rollback must stop Bandit first and reconcile post-cutover writes before
reviving Services; never simply reactivate the old source against stale data.

### Automation and required follow-up

Prior states (both hosts' `nixos-upgrade.service` were inactive/dead, linked):

| Host/timer | Prior state | Final state |
| --- | --- | --- |
| Services `nixos-upgrade.timer` | enabled, active/waiting | persistently masked, inactive |
| Bandit `nixos-upgrade.timer` | enabled, active/waiting | persistently masked, inactive |
| Services `podman-prune.timer` | enabled, active/waiting | restored enabled, active/waiting |
| Services `podman-container-refresh.timer` | enabled, active/waiting | unchanged enabled, active/waiting |
| Bandit `podman-prune.timer` | linked, inactive/dead | unchanged linked, inactive/dead |

Source pruning was runtime-masked only for the copy/deployment, then restored.
Refresh was not paused: inspection confirmed it references only networkoptimizer,
speedtest and redbot, not TypeType. No new refresh timer was introduced.

NixOS manages `/etc/systemd/system` as a read-only store symlink on these hosts,
so persistent masks reside in the higher-priority writable
`/etc/systemd/system.control/`, not conventional `systemctl mask` locations.
Both service and timer masks survived both relevant configuration switches;
they persist on disk across reboot (reboot itself was not tested).

**Do not restore upgrades until publication is separately authorized and the
upstream configuration includes this migration and downloader fix.** After
verifying that condition, explicitly authorize restoration. On each host,
run these commands via `ssh ... "bash -lc 'bash -s'"` or a Bash session:

```sh
sudo -n rm /etc/systemd/system.control/nixos-upgrade.service /etc/systemd/system.control/nixos-upgrade.timer
sudo -n rm /var/lib/typetype-migration/auto-upgrade-paused
sudo -n systemctl daemon-reload
sudo -n systemctl start nixos-upgrade.timer
systemctl show nixos-upgrade.timer nixos-upgrade.service -p Id -p LoadState -p ActiveState -p UnitFileState
```

The existing enabled timer links were preserved; no manual upgrade-service
start is needed. Check the next scheduled time: a persistent timer may trigger
promptly if an upgrade was missed. Leaving the masks indefinitely also delays
security updates, so publication/restoration requires follow-up.
