# Vikunja

Vikunja runs as the native NixOS service on the `services` host and is exposed
at `https://vikunja.basn.se`. It uses SQLite and local file storage on the
dedicated `tank/vikunja` dataset. Authentication is native OpenID Connect
against Authentik; nginx does not use forward-auth for this virtual host.

The locked package is Vikunja 2.6.0. Recheck its configuration keys and restore
compatibility whenever the package is upgraded.

## Deployment prerequisites

Do not push the enabled mount and service configuration until every prerequisite
below is ready. The `services` host automatically switches from the GitHub
repository overnight, so pushing an incomplete configuration can make the next
automatic upgrade fail on the missing mount or unavailable OIDC provider.

Before an explicitly authorized deployment:

1. Create `tank/vikunja` on `services` with `mountpoint=legacy`. Dataset
   creation is intentionally not performed by Nix.
2. Create `storage/backup-vikunja` on `vault` and grant the existing
   `zfsbackup` account `compression,mountpoint,create,mount,receive,rollback,destroy`
   on that dataset. The current delegation is scoped to `storage/backup` and
   does not cover this sibling. Although the existing ZnapZend daemon has
   global destination auto-creation enabled, provisioning and verifying this
   receiver remains a manual prerequisite.
3. Confirm both datasets are mounted or addressable as intended and that no
   existing receive destination uses `storage/backup-vikunja`.
4. Configure the Authentik provider and application described below, then
   verify its discovery URL returns successfully.
5. Confirm the host has its SOPS age key and can materialize both Vikunja
   credentials without displaying them.

The service has `RequiresMountsFor=/var/lib/vikunja`; a missing dataset prevents
startup. It uses a static `vikunja` account because systemd's `DynamicUser`
StateDirectory handling would otherwise use `/var/lib/private/vikunja` and
risk bypassing the mounted path. The static account keeps the module's
`StateDirectory=vikunja` directly on `/var/lib/vikunja`.

## Secrets

`machines/services/secrets/vikunja.yaml` contains two independently generated
secrets encrypted to the existing `basn` and `server_services` age recipients:

- `vikunja-service-secret` signs sessions and other cryptographic material.
- `vikunja-oidc-client-secret` authenticates the confidential OIDC client.

systemd loads them with `LoadCredential`. Vikunja reads them through the 2.6.0
`service.secret.file` and
`auth.openid.providers.authentik.clientsecret.file` settings. Vikunja expands
environment variables in these `.file` values, so the configuration uses
`$CREDENTIALS_DIRECTORY` without putting either value in the Nix store or the
service environment. Missing credential sources make systemd refuse startup.

Provision the OIDC client secret into Authentik through a trusted local SOPS
workflow that sends the decrypted value directly to a clipboard or password
manager. Do not print it, put it in shell history, or store a plaintext copy.

The encrypted repository and an authorized age private key are part of the
restore prerequisites. ZFS replication does not include `/run/credentials`,
the host age private key, or Authentik's copy of the client secret.

## Authentik

Create the provider before deploying Vikunja. Use a confidential OAuth2/OIDC
provider with these values:

- Application and provider slug: `vikunja`
- Client ID: `vikunja`
- Client secret: the encrypted Vikunja OIDC secret
- Issuer/discovery base: `https://auth.basn.se/application/o/vikunja/`
- Strict redirect URI: `https://vikunja.basn.se/api/v1/auth/openid/authentik/callback`
- Scopes: `openid profile email`

Do not add `vikunja_scope`, a `vikunja_groups` claim, team mappings, a proxy
provider, or an outpost. Vikunja's email and username fallback linking are also
disabled.

Bind an Authentik policy to the application that permits only explicitly
authorized users or members of a dedicated group such as `Vikunja Users`.
Verify the binding applies to application access, not only to a launch tile,
and verify an unbound user is denied. Disabling Vikunja's local registration
does not prevent an authenticated OIDC identity from being provisioned on its
first login.

`requireavailability` is enabled. Vikunja retries discovery and exits if the
provider remains unavailable; systemd then restarts it. Local authentication
and registration are disabled, so there is no fallback login path.

CalDAV is initially disabled. Most CalDAV clients use HTTP Basic authentication,
which is not compatible with this OIDC-only deployment without a separate
application-password design.

## Limits and hardening

- Task attachments are limited to 20 MiB.
- nginx accepts at most 32 MiB per request to allow multipart overhead.
- Vikunja import archives are limited to 20 MiB, 1,000 files, and 256 MiB of
  per-user imported storage; CSV imports are limited to 10,000 rows.
- Authenticated requests are limited to 100 per minute. Vikunja's separate
  unauthenticated, token-refresh, and failed BasicAuth limits remain enabled.
- Client addresses come from `X-Forwarded-For` only when the immediate proxy is
  `127.0.0.1/32`.
- Link sharing, public teams, local login, self-registration, SMTP, reminder
  email, Sentry, external background lookup, and plugins are disabled.

## Replication

ZnapZend snapshots `tank/vikunja` every four hours and retains four-hour
snapshots for one day and daily representatives for one week locally. On each
normal four-hour source run it transfers the new snapshot, plus missed
intermediate snapshots when catching up. Destination cleanup retains daily
representatives for 30 days on the independent `storage/backup-vikunja`
dataset.

The receiver is deliberately a sibling of the existing recursive Vaultwarden
destination, `storage/backup`. ZnapZend receives with rollback enabled and uses
recursive snapshot cleanup for recursive plans, so nesting this receiver under
`storage/backup` could let Vaultwarden rollback or cleanup affect Vikunja.

A recursive ZFS snapshot captures `vikunja.db`, its `-wal` and `-shm` companions,
and the files tree at one filesystem instant. This is SQLite crash-consistent:
SQLite can replay or discard complete WAL transactions after restoration. It
does not guarantee application-level transactional consistency between a
committed database row and an attachment write performed as a separate
operation. It is intentionally not an unqualified copy of a live SQLite file.

No Uptime Kuma heartbeat is configured for this replication yet. Create a
dedicated push monitor and encrypt its unique token before adding a `postsend`
hook. Do not reuse the Vaultwarden heartbeat because that would hide independent
replication failures. Until then, inspect ZnapZend failures and compare the
latest source and receiver snapshot GUIDs during maintenance.

Before upgrades, schema migrations, or other high-risk maintenance, an operator
may create a quiesced snapshot: stop Vikunja, confirm it has closed SQLite,
snapshot the complete dataset, and start it again. This is a live operation and
requires explicit authorization. Record the Vikunja version and repository
revision alongside the maintenance snapshot.

## Restore drill

Test restores in an isolated dataset and namespace. Never receive, clone, mount,
or roll back over `/var/lib/vikunja` during a drill.

Prerequisites for a meaningful drill are:

1. The exact Vikunja version that wrote the snapshot, before allowing any newer
   binary to run migrations.
2. A replicated snapshot whose source and receiver GUIDs match.
3. The encrypted repository revision, an authorized age key, and access to an
   Authentik test client with the matching OIDC secret.
4. Enough space for an isolated clone or receive target.

Clone or receive the snapshot into the isolated target, preserving the database,
WAL, SHM, and files together. With no Vikunja process using it, run SQLite
`PRAGMA quick_check` against the restored database. Then start the same Vikunja
version against the isolated copy, with networking constrained so it cannot
replace production OIDC callbacks, and verify representative projects and
attachments. Only after that succeeds should an upgrade rehearsal be allowed
to migrate a second disposable clone.

For a production restore, first preserve the damaged dataset and current
snapshot history, document the selected recovery point, and obtain explicit
authorization. Restore the encrypted secrets separately, verify the Authentik
client still matches, receive the complete dataset while Vikunja is stopped,
run SQLite integrity checks, and only then start the pinned version. Avoid an
in-place rollback unless its effect on newer snapshots and replication history
has been reviewed.
