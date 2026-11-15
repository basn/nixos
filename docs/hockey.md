# Hockey CLI

Read-only official Swehockey schedules and roster checks in the Hermes terminal.

```sh
hockey
hockey --json
hockey player-key
hockey --match FIXTURE_ID
hockey player-key --match FIXTURE_ID
```

The default checks every privately configured player; keys select a subset.
Output uses Europe/Stockholm time and includes source coverage and warnings.
Team fixtures are not proof of participation; lineup listings are not ice time.
Missing sources, identity mismatches, expired mappings and ambiguous fixtures
remain unknown/partial rather than becoming a claim of no game. Failures exit nonzero.
Existing approvals and unattended/cron restrictions are unchanged.

## One-shot match JSON

`--match FIXTURE_ID` implies JSON and defaults to all configured players (the
existing positional keys select a subset). Use the `fixture_id` returned by
fixture lookup, **not** the number in a game URL. The exact Events link is read
from a verified official schedule; fixture and game numbers differ and are never
converted or calculated. Existing `hockey`, selectors and `--json` retain their
fixture-lookup behavior. No polling, notifications, credentials or snapshot state
storage are added.

The response has `fixture_id`, `match`, `players`, source retrieval coverage and
errors. `match` retains schedule information even when an individual match source
fails. Its schedule `status` is separate from `summary.status`; only the official
match panel's **Final Score** establishes `summary.status: final`. A numeric score,
past kickoff, period totals, last action or schedule round annotation such as
“Final” does not. Unknown panel wording stays unknown. `summary.score` is
`[home, away]`; `period` and `clock` are null unless explicitly recognized in the
panel. `panel_text` preserves published wording when the panel is available.
`latest_event` is the last published action's period and cumulative time, **not**
the current match clock or proof of live play. No countdown or period-local time
is inferred. Schedule postponements/cancellations are retained even without a
match link; conflicting or unavailable panel information remains separate.

Each player separates:

- `identity`: roster name/date-of-birth verification for a configured fixture team.
- `lineup.status`: `listed`, `not_listed` in a published team lineup, or
  `unconfirmed` for unpublished, empty, invalid or unavailable lineups. None is
  proof of ice time. Roster failures prevent configured-player evidence claims.
- `direct_events`: goal/assist references supported by an exact verified name and
  team match in Actions, independently of lineup availability. Team abbreviations
  are resolved from the verified match page's title, not a private mapping.
- `event_evidence`: `direct_event`, `none_in_snapshot`, `unknown`, or
  `not_applicable` when no configured team is in this fixture. Zero `goals`/`assists`
  means no such credit in a complete recognized snapshot, not proof of not playing.
  Incomplete or ambiguous attribution leaves totals null; retained direct evidence
  is a lower bound, not a complete total.

`match.events` contains goal credits with scorer, separate assists, score, team
code, period, cumulative `time` and source URL. Participation-number lists are
not assists, and tournament totals in tooltips are not player/event IDs.

### Deduplication and corrections

These pages expose no official event IDs, player IDs or correction history.
`id_kind: derived_score_transition` labels an event key derived from fixture ID
and the resulting home-away score; `revision` is a deterministic SHA-256 content
fingerprint. Identical parsed snapshots have identical keys/revisions, independent
of selected player, fetch time, last-update heading or row position. Scorer/assist
corrections keep the key but change the revision; corrected score transitions can
replace keys. Ambiguous repeated transitions are marked incomplete and retained
with revision-qualified keys; these are not immutable official identities.

Treat output as a **replacement snapshot, not an append-only event feed**. Replace
prior goal keys, including removals, only when `match.events_complete` is true:
the recognized Actions rows' scoring transitions and team codes must reconcile
with the panel score. This describes the current published snapshot, not upstream
finality or an atomic transaction across sources. On failed/partial reads, retain prior evidence
and do not infer retractions from absent keys. `attribution_complete` additionally
requires recognized scorer/assist fields; require it before replacing player
credit totals (which also require verified identity/team attribution). A correction
may transfer an old credit to a different player or remove an assist entirely.
Consumers needing perfect immutable identity or historical change tracking need
a different official source; this CLI cannot provide either.

Exit **0** means all requested coverage was recognized; it does not mean the match
is final. Exit **1** accompanies partial/unavailable JSON, including missing links,
unpublished lineups, identity/parser/network failures, or fixture not found in
successfully checked configured-team schedules. Failed schedule coverage cannot
prove that a fixture does not exist. Argument syntax errors use argparse exit 2.
Read useful retained fields and per-player/match errors even after exit 1.

Synthetic regression checks (no network or private configuration):

```sh
nix shell --inputs-from . nixpkgs#python3 -c python3 -B -m unittest discover -s scripts -p test_hockey.py
```

## Private runtime configuration

Only SOPS-encrypted configuration belongs in this repository. Never embed
plaintext player data in Nix expressions, derivations, images or the Nix store.
`machines/hermes/secrets/hockey-players.json` is a JSON envelope around an
encrypted binary payload, hiding private player-selector keys as well as values.
No plaintext private player JSON or captured pages belong in this repository.
Explicitly requested synthetic hockey tests are permitted: fictional names,
dates, teams and generated HTML only; never private mappings or captured pages.

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
