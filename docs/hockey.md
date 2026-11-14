# Hockey CLI

Read-only official Swehockey schedules and roster checks in the Hermes terminal.

```sh
hockey
hockey --json
hockey player-key
```

The default checks every privately configured player; keys select a subset.
Output uses Europe/Stockholm time and includes source coverage and warnings.
Team fixtures are not proof of participation; lineup listings are not ice time.
Missing sources, identity mismatches, expired mappings and ambiguous fixtures
remain unknown/partial rather than becoming a claim of no game. Failures exit nonzero.
Existing approvals and unattended/cron restrictions are unchanged.

## Private runtime configuration

Only SOPS-encrypted configuration belongs in this repository. Never embed
plaintext player data in Nix expressions, derivations, images or the Nix store.
`machines/hermes/secrets/hockey-players.json` is a JSON envelope around an
encrypted binary payload, hiding private player-selector keys as well as values.
No plaintext player JSON, captured pages or hockey tests belong in this repository.

The image wrapper supplies `--config /run/hockey-players.json` to the script.
Direct script invocation requires an explicit `--config /private/path.json`.
The minimal JSON fields are:

- Root: `season`, `valid_from`, `valid_until`, `players`.
- `players`: an object keyed by private CLI selectors.
- Each player: `official_name`, `birth_date`, `teams`.
- Each team entry: `team`, `schedule`, `roster`.

Dates use ISO format; validity includes `valid_from` but excludes `valid_until`.
The season must match the official pages. Roster identity requires both the exact
official name and date of birth. Team labels must match the official roster.
Schedule and roster URLs must use the allowed HTTPS Swehockey endpoints.
There is no separate display name, evidence, profile URL or verification metadata.
Reverify identity, team mappings, season and validity bounds before renewal.

## Secret renewal and activation

Re-encrypt a verified private file kept outside the repository using the existing
Hermes recipients in `.sops.yaml` (run from the repository root):

```sh
sops --encrypt --input-type binary --output-type json \
  --filename-override machines/hermes/secrets/hockey-players.json \
  /private/path.json > machines/hermes/secrets/hockey-players.json
```

Keep binary input mode: structured JSON encryption would expose selector keys.
SOPS provisions `/run/secrets/hockey-players` as root:root, mode `0400`, on
successful system activation or boot. The root-running terminal sandbox mounts
it read-only at `/run/hockey-players.json`. Building alone neither decrypts nor
deploys the secret; no manual host plaintext setup is needed.

Initial migration and later renewals require separately authorized sandbox
recreation: existing file bind mounts retain the old secret generation, and a
Hermes service restart alone does not refresh them. Follow the
[activation policy](../machines/hermes/README.md#activation-boundary): quiesce
Hermes and the old sandbox before replacement, preserving the stopped container
until verification succeeds.

Before authorized recreation, verify the runtime secret resolves to a **regular
file**, owned by root:root with mode `0400`, without displaying its contents.
Do not recreate the shared terminal container before this check succeeds:
a missing bind source may become a directory or prevent container startup,
breaking unrelated terminal commands too. If decryption fails, defer recreation
rather than launching the container with a missing source.
Repository changes alone leave the existing live container unaffected.

The preserved private backup is temporary, not permanent secure storage.
Older build/store artifacts may still contain previous data; this refactor does
not remove them. Handle retention separately, without indiscriminate garbage collection.
