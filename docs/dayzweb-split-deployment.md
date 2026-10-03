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
   to the `services` peer and denies other peers. The host firewall is an
   independent second layer and accepts only source `100.86.229.241` on `wt0`.
4. Confirm NetBird still assigns `100.86.89.177` to `services` and
   `100.86.229.241` to `nixos-sov2`, and that
   `services.netbird.basn.se` resolves to `100.86.89.177` from `nixos-sov2`.
   Correct the repository configuration before deployment if either address
   changed.

Until the encrypted token file exists, evaluation emits a warning, neither the
ingest service nor worker timer is enabled, and both services have a runtime
condition on `/run/secrets/dayzweb-ingest-token`.

## Validate and stage

From clean DayZWeb and NixOS checkouts, run the documented test suite and build
both affected NixOS outputs. Do not update either flake lock while validating.
Record the DayZWeb commit and use that exact revision for both hosts.

Stage the archive under `/srv/dayzweb/releases/<commit>` on both hosts without
changing either `current` symlink. Verify the staged trees are complete and
owned by root but readable by the `dayzweb` account. Do not use
`release-to-services` for this migration: it updates only one host and restarts
the web service immediately.

## Switchover

1. On `services`, stop and disable `dayzweb-collect.timer` before enabling or
   manually starting the new worker. Stop any active `dayzweb-collect.service`
   invocation and verify both old units are inactive.
2. Stop `dayzweb.service` briefly so no process can write the database. Take a
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
5. From `nixos-sov2`, verify DNS and TCP reachability over NetBird. Also verify
   another peer cannot reach port 18111; do not weaken the host firewall to
   make this check pass.
6. Activate the validated `nixos-sov2` generation. Run one manual
   `dayzweb-collector.service` invocation and inspect its focused journal. Only
   after it completes successfully should `dayzweb-collector.timer` remain
   enabled for the hourly persistent schedule.
7. Confirm the old `dayzweb-collect` service and timer remain disabled and that
   only the services-host ingest process writes SQLite. Check that the web UI
   and collection history show the expected new successful collection.

Rollback must stop the new worker timer first. Restore the previous matching
revision on both hosts; restore the SQLite backup only while every database
writer and the web service are stopped. Never run the old and new collectors
at the same time.
