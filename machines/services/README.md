# Services

Flake output: `services`.

Services is the general application host. It runs Podman workloads, Blocky,
Nginx, Uptime Kuma, py-kms, Vaultwarden, Vikunja, the AC service, monitoring,
Authentik, FreshRSS, SearxNG, the network optimizer, and ZnapZend. Service
modules live in `services/`; SOPS declarations are in `sops.nix`.

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

Network Optimizer and its companion speed-test image are pinned to 2.10.7,
confirmed as the latest stable GitHub release on 2026-11-05 (2.11 previews are
excluded). Both multi-architecture index digests were verified on that date
against GHCR's registry manifest endpoints and locally calculated SHA-256 hashes;
both include linux/amd64 and linux/arm64. The
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

```sh
nix build .#nixosConfigurations.services.config.system.build.toplevel --no-link
```
