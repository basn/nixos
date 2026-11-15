# Services

Flake output: `services`.

Services is the general application host. It runs Podman workloads, Blocky,
Nginx, Uptime Kuma, py-kms, Vaultwarden, Vikunja, the AC service, monitoring,
Authentik, FreshRSS, SearxNG, the network optimizer, and ZnapZend. Service
modules live in `services/`; SOPS declarations are in `sops.nix`.

The Hermes API ingress `api.hermes.basn.se` proxies only the exact model-list
and chat-completion routes to Hermes, using its bearer auth rather than the
Authentik helper. Blocky maps it to `10.1.1.8` internally. Public DNS and ACME
validation remain deployment prerequisites; the dashboard/OIDC are unchanged.
See [Hermes API details](../hermes/README.md#opencode-api).

## Configured services

- Podman and managed container refresh/prune jobs; Blocky; Nginx; and Uptime
  Kuma.
- Authentik, Vaultwarden, Vikunja, FreshRSS, SearxNG, py-kms, the AC service,
  and the network optimizer.
- Prometheus/Grafana monitoring, ZnapZend, OpenSSH, ZFS auto-scrub, and TRIM.

Vikunja deployment prerequisites, authentication policy, backup, and restore
procedures are documented in [`../../docs/vikunja.md`](../../docs/vikunja.md).
The PinePods public ingress and declarative Authentik application are documented
in [`../../docs/pinepods.md`](../../docs/pinepods.md).
The Muxarr public ingress and manual Authentik prerequisites are documented in
[`../../docs/muxarr.md`](../../docs/muxarr.md).
TypeType's public TLS/auth ingress remains here and relays to Bandit; the
completed cold cutover, user-reported functionality and auto-upgrade pause are documented in
[`../../docs/typetype.md`](../../docs/typetype.md).

Network Optimizer and its companion speed-test image are pinned to 2.11.2.
The [2.11.2 stable release](https://github.com/Ozark-Connect/NetworkOptimizer/releases/tag/v2.11.2)
and both GHCR index digests were verified on 2026-11-15: registry digests match
locally calculated SHA-256 hashes, both include linux/amd64 and linux/arm64,
and amd64 revision labels match release commit
`3bdd96f84769ef243041a3a325554a34aef41ad7`.
This release fixes SNMP readings, snapshots and dashboard status and precompiles
pages. Review the [2.11.0](https://github.com/Ozark-Connect/NetworkOptimizer/releases/tag/v2.11.0)
and [2.11.1](https://github.com/Ozark-Connect/NetworkOptimizer/releases/tag/v2.11.1)
notes before deployment; back up persisted
state and test recovery first. The SNMP fix needs no On-Site Agent upgrade;
agent upgrades and gateway traceroute installation are separate live operations.
2.11 adds Change Control writes and optional CAKE shaping; do not apply plans or
deploy shaping without separate authorization (the first Adaptive SQM deploy
after upgrading can drop packets on every WAN for about a second). Review the
default-enabled per-site Live Traffic/DNS capture setting before upgrading an
On-Gateway Agent; flows and lookups are held in memory while the page is open.
No deployment or runtime compatibility is established by these pins.

Earlier upgrade context: the
[2.10.7 release notes](https://github.com/Ozark-Connect/NetworkOptimizer/releases/tag/v2.10.7)
cover connection recovery, Multi-WAN tracing, monitoring and alert fixes, Go
security updates, and Alpine brotli/curl/expat security fixes in the speed-test
image. AP Agents receive rebuilt binaries automatically after deployment.
The optional 2.10.7 On-Site Agent update fixes Multi-WAN source-bound traces on
UniFi gateways without traceroute; it is not performed here. The separately
managed netopt-waf 1.0.4 update fixes blank pages behind WAF Block mode and is
offered in the application's WAF page, not deployed by these pins. The preceding
[2.10.6 release notes](https://github.com/Ozark-Connect/NetworkOptimizer/releases/tag/v2.10.6)
cover Path Localization, server-side logout, and nginx security updates in the
speed-test image. The intervening
[2.10.5 release notes](https://github.com/Ozark-Connect/NetworkOptimizer/releases/tag/v2.10.5)
also describe alert behavior changes, including automatically enabling WAN
degradation alerts on a site's first successful WAN speed test unless customized.
Existing 2.10.3–2.10.6 On-Site Agents remain compatible; older agents may still
use three rather than five probes for Path Localization, and the Multi-WAN
tracing fix requires the 2.10.7 Agent.
The accepted rolling license policy remains documented in the
[2.10.4 release notes](https://github.com/Ozark-Connect/NetworkOptimizer/releases/tag/v2.10.4):
each release converts to Apache 2.0 three years after publication.

## Container upgrade backups

`tank/docker`, including the persisted Authentik and network optimizer state,
is not covered by the configured ZnapZend datasets. Before deploying an image
upgrade for either service, create and verify a recoverable backup of its
persisted state. Repository image-pin changes do not perform that live backup.

## PostgreSQL security maintenance gate

Authentik's PostgreSQL pin is 17.12 (previously 17.11). Its official Docker Hub
multi-architecture index digest was checked against the registry and a local
SHA-256 on 2026-11-15, including the linux/amd64 manifest and configuration.
[CVE-2026-6460](https://www.postgresql.org/support/security/CVE-2026-6460/)
is fixed in 17.12 and 18.7. The
[17.12](https://www.postgresql.org/docs/release/17.12/) and
[18.7](https://www.postgresql.org/docs/release/18.7/) release notes require these
gates for Authentik, [TypeType](../../docs/typetype.md) and
[PinePods](../../docs/pinepods.md), not just an image replacement:

- Before deployment, obtain fresh recoverable backups of every application
  database and cluster roles/globals; test restoration with the target image and
  retain independent recovery copies. Authentik's `/docker/authentik/backups`
  directory is provisioned, but no recurring backup is configured here.
- Inventory extensions and C-language functions in **every database**, plus
  shared/session/local preloads and their libraries. No custom extensions or
  preloads are declared here; the live inventory is unknown. Rebuild C extensions
  against the target PostgreSQL release for full protection; some require source
  changes. Verify target builds and compatibility before switching. Do not disable
  `composite_type_mismatch` protections to make an extension work.
- Minor upgrades within each major do not require dump/restore. Review affected
  indexes and plan authorized `REINDEX` after updating: unconstrained `bpchar`
  btree columns (not `CHAR(n)`), suspected GIN vacuum/page-split corruption, and
  TOAST indexes affected by concurrent reindexing/"missing chunk" errors.
  PostgreSQL 18 also needs review of parallel GIN builds with keys over 65535 bytes.
- No PostgreSQL incremental backup is configured here, but verify live usage.
  Existing incremental files are untrusted; if used, take a new full backup
  **after updating** as the next incremental baseline. Updating alone does not
  repair existing WAL summaries. PinePods' logical dumps are not incremental.

All backups, restores, reindexing, restarts and deployment require explicit live
authorization. This repository patch performs none and is not live remediation.

## Grafana package update

After the 2026-11-15 named-input lock refresh, Services' configured native
Grafana package evaluates to 13.0.13 from the primary stable nixpkgs input
(previously 13.0.12). No host package override is needed. Evaluation alone does
not establish a successful system build or deployment; nothing live was changed.

```sh
nix build .#nixosConfigurations.services.config.system.build.toplevel --no-link
```
