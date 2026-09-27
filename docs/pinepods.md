# PinePods

PinePods 0.9.0 runs on `bandit` as three rootful Podman containers: PinePods,
PostgreSQL 18.6, and non-persistent Valkey 8.1.10. The images are version and
multi-architecture manifest digest pinned in
`machines/bandit/services/pinepods.nix`. PostgreSQL and Valkey are on the
private `pinepods` Podman network and publish no host ports.

The PostgreSQL and Valkey pins were refreshed on 2026-09-24 from the official
[PostgreSQL](https://hub.docker.com/_/postgres) and
[Valkey](https://hub.docker.com/r/valkey/valkey) Docker Hub repositories. The
selected tags were published on 2026-09-21 and are the newest stable patch tags
in the requested PostgreSQL 18 and Valkey 8.1 lines; moving from 18.0 to 18.6 and
8.1.3 to 8.1.10 takes accumulated fixes without changing a major or minor line.
The digest pins the multi-architecture manifest while retaining the readable
tag. PinePods remains at the requested 0.9.0 release.

Public HTTPS terminates on the `services` host at `https://pods.basn.se` and is
proxied to Bandit's port 80. Bandit's nginx only accepts that virtual host from
`10.1.1.8/32`, then relays to PinePods on `127.0.0.1:8040`. PinePods uses native
OIDC; this virtual host does not use Authentik forward auth. The trusted Bandit
hop preserves the client and original HTTPS forwarding headers normalized by
the public ingress rather than replacing the scheme with its local HTTP hop.

## Deployment prerequisites

Do not push or deploy the enabled configuration until all prerequisites are
complete. Both hosts auto-upgrade from the repository, and missing datasets or
SOPS keys intentionally prevent an incomplete deployment from starting.

Before an explicitly authorized deployment:

1. Ensure `data/pinepods` and its child datasets exist on Bandit. They were
   created during the initial test deployment; do not recreate them. The
   original creation commands were:

   ```sh
   sudo zfs create -o mountpoint=legacy data/pinepods
   sudo zfs create -o mountpoint=legacy data/pinepods/postgres
   sudo zfs create -o mountpoint=legacy data/pinepods/downloads
   sudo zfs create -o mountpoint=legacy data/pinepods/backups
   ```

   Do not create a new pool or set a quota. The datasets inherit encryption from
   the existing `data` encryption root. Before switching, verify each reports
   `encryptionroot=data` and `mountpoint=legacy` without printing key material.
2. Confirm the encrypted SOPS documents contain Bandit's PostgreSQL bootstrap,
   application database, local administrator, and OIDC client secrets, plus the
   same OIDC client secret on `services`. Never place plaintext values in the
   repository, terminal history, documentation, or process arguments.
3. Confirm Authentik contains the existing user with username `basn`. The
   declarative blueprint creates a new `pinepods` group with that user, a
   confidential provider, the application, and a group-only application policy.
   If a group named `pinepods` already exists, the non-destructive `created`
   state preserves its membership and an administrator must add `basn` manually.
4. Verify routing preserves `10.1.1.8` as the source from `services` to Bandit.
   If the router starts applying source NAT, update Bandit's nginx ACL to the
   verified single ingress address before deployment; do not broaden it to a
   subnet.
5. Build both affected host outputs, then deploy only with explicit approval.

The four mounts use legacy ZFS mount units. `pinepods-storage.service` has
`RequiresMountsFor` on every path and initializes ownership only after all
datasets are mounted, preventing writes into hidden directories on the root
filesystem. It sets the PostgreSQL dataset to Alpine's documented PostgreSQL
UID/GID `70:70` and does not use Podman's recursive `:U` remapping. Container
units require this service.

## Database and bootstrap

PostgreSQL stores `PGDATA` at `/var/lib/pgdata/pgdata` while the host dataset is
bound to `/var/lib/pgdata`, matching PostgreSQL 18's changed image volume. The
image bootstrap account is `pinepods_owner`; an init script creates the separate
non-superuser `pinepods` login and transfers ownership of only
`pinepods_database` to it. PinePods receives only the application credential.
The init script imports that credential with psql's `\getenv`, so it never
appears in the process argument list. Application readiness performs a real TCP
query as the non-superuser role; the official image's temporary initialization
server does not listen on TCP, so this cannot admit PinePods before init scripts
finish and the final server starts.
Changing the application password after database initialization also requires
an authorized `ALTER ROLE pinepods PASSWORD ...` operation; changing SOPS alone
does not rotate PostgreSQL's stored role password. The same caveat applies to
the bootstrap superuser and local administrator: their environment values are
initialization inputs, not automatic password-rotation mechanisms.

PinePods receives a SOPS-backed local recovery administrator password and
creates `basn-local` during the initial migration. This closes the unauthenticated
first-admin setup window before public ingress is useful and leaves a recovery
path if OIDC is unavailable. The recovery account uses a reserved email address
that cannot match the Authentik user, because PinePods links OIDC identities to
existing users by email. Standard login remains enabled deliberately.
Protect and rotate this credential; Authentik group restriction does not disable
local accounts or local login.

PinePods 0.9.0 initializes `AppSettings.SelfServiceUser` to `false`. Its public
`add_login_user` endpoint checks that setting and rejects registration while it
is false, so self-registration is disabled on a fresh deployment. Do not enable
the **Self Service User** administrator setting unless unrestricted local signup
is intended. Verify the public self-service status remains disabled after first
startup and after restores.

The OIDC provider is also initialized directly from PinePods environment
variables and cannot be removed in the UI. Its callback is exactly
`https://pods.basn.se/api/auth/callback`. PinePods 0.9.0 mobile clients store a
`pinepods://auth/callback` origin and PKCE verifier internally, but the server
still exchanges the authorization code as the same confidential client using
the HTTPS callback. Do not add a custom-scheme redirect or make the Authentik
client public.

OIDC role-to-admin mapping is disabled. Authentik's application policy is the
authorization boundary, so only members of `pinepods` may complete OIDC login;
OIDC users are ordinary PinePods users. The blueprint uses `state: created` for
the group, which adds `basn` only when creating the group and never overwrites
later membership changes. If the group pre-exists, add `basn` manually. Test
both an allowed user and an unbound user after deployment.

Rotating the OIDC client secret requires updating both hosts' SOPS values,
allowing the Authentik blueprint to reconcile the provider, and updating the
environment-initialized PinePods provider through an authorized database or UI
procedure. PinePods 0.9.0 skips environment initialization when that client ID
already exists, so changing SOPS and restarting alone is insufficient.

## Backups and restore

`pinepods-postgres-backup.timer` writes a daily custom-format logical dump to
`/data/pinepods/backups` and retains 14 days. PinePods may also place its own
exports there. This dataset is on the same encrypted pool as the database and
is not an independent backup.

The backup authenticates as the non-superuser over TCP to `127.0.0.1`; this
avoids the official image's local-socket trust rule. The password is inherited
into `podman exec` through its environment and is not included in command-line
arguments.

No Bandit snapshot or off-host replication policy currently covers these new
datasets. Before treating the service as durable, choose and implement an
explicit recursive snapshot and off-host replication target using the existing
repository patterns. That expansion is intentionally not included silently in
this change. Until then, copy and verify logical dumps off-host through an
authorized process.

For a restore, stop PinePods before changing its database, preserve the damaged
datasets and current snapshots, restore a selected `pg_dump` with the pinned
PostgreSQL major version, and verify database ownership remains with the
non-superuser `pinepods` role. Restore downloads separately as needed. Then
start PinePods and verify local recovery login, Authentik login, representative
subscriptions, and downloaded media. Every live stop/start, dataset operation,
restore, or deployment requires explicit authorization.

## Validation limits

A NixOS toplevel build validates module evaluation, generated systemd units,
nginx syntax, store paths, and SOPS key declarations. It does not pull or start
OCI images, initialize PostgreSQL, apply the Authentik blueprint, request a TLS
certificate, or exercise browser/mobile OIDC. Runtime verification therefore
still requires an explicitly authorized deployment followed by container health,
blueprint reconciliation, allowed/denied OIDC login, local recovery login,
self-registration denial, backup, and restore checks.
