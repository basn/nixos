# DayZWeb split deployment

This runbook stages the same tested DayZWeb revision on `services` and
`nixos-sov2`, then moves collection from the old services-host timer to the
private ingest API and the new worker. Repository validation does not authorize
these live operations.

## One-time prerequisites

1. Create `secrets/dayzweb-ingest-token.yaml` with SOPS. Its YAML key must be
   `token`, and its value must be an independently generated random secret of
   at least 32 bytes. Do not put the plaintext in a Nix expression, command-line
   argument, shell history, or unencrypted file.
2. Use the existing repository `.sops.yaml` rule for `secrets/`, which includes
   both the `services` and `nixos-sov2` age recipients. Check the encrypted
   file's SOPS metadata without decrypting it, and commit only the encrypted
   file.
3. Add a NetBird policy that permits TCP port 18111 from the `nixos-sov2` peer
   to the `services` peer and denies other peers. The services host firewall
   opens TCP port 18111 normally; the NetBird policy provides the peer-level
   restriction, while the ingest process still binds only to the services
   NetBird address.
4. Confirm NetBird still assigns `100.86.89.177` to `services` and
   `100.86.229.241` to `nixos-sov2`, and that
   `services.netbird.basn.se` resolves to `100.86.89.177` from `nixos-sov2`.
   Correct the repository configuration before deployment if either address
   changed.
5. For Steam presence polling, provision the Steam Web API key directly on
   `nixos-sov2` as `/var/lib/dayzweb-secrets/steam-api-key`, with the directory
   owned by root mode `0700` and the non-empty file owned by root mode `0600`.
   This separate runtime credential must never enter Git, the Nix store, logs,
   command-line arguments, or the ingest-token secret.

Until the encrypted token file exists, evaluation emits a warning, neither the
ingest service nor worker timer is enabled, and both services have a runtime
condition on `/run/secrets/dayzweb-ingest-token`.

Local retention is independent: `dayzweb-maintenance.timer` is enabled on the
ingest host (`services`) hourly with `Persistent=true`, even without the token.
It runs `python -m app.maintenance` as `dayzweb` against the ingest database,
with read-only application source, only the database directory writable, and
`PrivateNetwork=true`. It needs neither credentials, NetBird, the network nor
the ingest process. It is not installed on `nixos-sov2`. It removes Steam
presence samples older than 30 days and unreferenced expired batches.

The worker's three existing poller timers stay enabled: Aftermath keeps its
hourly `:05` schedule and random delay; population and Steam keep their 120-second
sampling intervals. Population's service deadline is 120 seconds (query and
ingest retries plus margin); Steam's is 90 seconds (three sequential HTTP
requests at up to 20 seconds each plus margin).

## Validate and stage

From clean DayZWeb and NixOS checkouts, run the documented test suite and build
both affected NixOS outputs. Do not update either flake lock while validating.
Use DayZWeb release `837284c31e47e7ef8e9770eac98406fd9c5936db` on both hosts.
Do not use `dayzwebpush` for this deployment.

Before publishing the NixOS commit or switching either host, record each host's
fresh `/run/current-system` target and `/srv/dayzweb/current` resolved target,
plus the enabled/active state of all DayZWeb timers and `nixos-upgrade.timer`.
Use these per-host values for rollback, not targets copied from an earlier
deployment. Inspect `nixos-upgrade.service`; wait for any running upgrade to
finish, then coordinate pausing auto-upgrade on both hosts for the authorized
deployment window. Publishing to GitHub can otherwise activate maintenance
before the application containing `app.maintenance` has been staged and selected.
Do not publish early; restore the recorded auto-upgrade state only after both
hosts are validated and the published revision matches the intended deployment.

Stage the archive under `/srv/dayzweb/releases/<commit>` on both hosts without
changing either `current` symlink. Verify the staged trees are complete and
owned by root but readable by the `dayzweb` account. Do not use
`release-to-services` for this migration: it updates only one host and restarts
the web service immediately.

## Switchover

1. Pause the worker's three poller timers and the services maintenance timer
   for the deployment window, and wait for or stop active invocations. On
   `services`, stop and disable `dayzweb-collect.timer` before enabling or
   manually starting the new worker. Stop any active `dayzweb-collect.service`
   invocation and verify both old units are inactive.
2. Stop `dayzweb.service`, `dayzweb-ingest.service` and any active
   `dayzweb-maintenance.service` so no process can write the database. Take a
   consistent SQLite backup of `/var/lib/dayzweb/dayzweb.sqlite3` using the
   SQLite `.backup` API, and store the backup on the same protected ZFS dataset.
   Do not copy only the main SQLite file while a writer or WAL may be active.
3. Atomically repoint `/srv/dayzweb/current` on both hosts to their staged
   directories for the same commit. Verify both symlinks before starting any
   new unit.
4. Activate the validated `services` NixOS generation first. Confirm the SOPS
   token exists and is non-empty by checking only file metadata, never content.
   Verify `dayzweb-ingest.service` is active, bound only to
   `100.86.89.177:18111`, and that `dayzweb.service` is using the same revision.
   Run maintenance once, confirm success without credentials/network access,
   and verify its hourly persistent timer is enabled. A switch can re-enable
   timers; keep the worker timers paused until the new ingress is healthy.
5. From `nixos-sov2`, verify DNS and TCP reachability over NetBird. Also verify
   another peer is denied by the NetBird policy. The host firewall opens the
   port normally and is not the peer-level access-control boundary.
6. Activate the validated `nixos-sov2` generation. Run one manual
   `dayzweb-collector.service` invocation and inspect its focused journal. Only
   after it completes successfully should `dayzweb-collector.timer` remain
   enabled for the hourly persistent schedule.
7. Confirm the old `dayzweb-collect` service and timer remain disabled and that
   only services-host web, ingest and maintenance processes write SQLite. Check
   that the web UI and collection history show the expected successful collection.
8. For Steam polling, verify only the key file's owner, mode, and non-empty
   status. Run `dayzweb-steam-collector.service` once in its normal credential
   context, then leave `dayzweb-steam-collector.timer` enabled only after that
   succeeds. An empty shared watch list is a successful no-op and does not
   validate the key against Steam; never add a production watch as a smoke test.
9. Validate population once and confirm all three worker timers remain enabled,
   with population/Steam deadlines of 120/90 seconds. Check both current-system
   and application targets, failed units, and focused journals, then restore
   the recorded auto-upgrade state after checking the published NixOS revision.

Rollback must pause auto-upgrade and stop all three worker timers and the
maintenance timer first, then stop active collectors. Before any SQLite restore,
stop every local writer: web, ingest, maintenance and any legacy collector;
verify all are inactive. Restore each host's freshly captured system generation
and application target, not stale historical paths. Restore the SQLite backup
only with every writer stopped, and validate ingress before restarting workers.
Restore only the intended timer/auto-upgrade states. Never run the old and new
collectors at the same time.
