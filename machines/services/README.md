# Services

Flake output: `services`.

Services is the general application host. It runs Podman workloads, Blocky,
Nginx, Uptime Kuma, py-kms, Vaultwarden, the AC service, monitoring,
Authentik, FreshRSS, SearxNG, the network optimizer, and ZnapZend. Service
modules live in `services/`; SOPS declarations are in `sops.nix`.

## Configured services

- Podman and managed container refresh/prune jobs; Blocky; Nginx; and Uptime
  Kuma.
- Authentik, Vaultwarden, FreshRSS, SearxNG, py-kms, the AC service, and the
  network optimizer.
- Prometheus/Grafana monitoring, ZnapZend, OpenSSH, ZFS auto-scrub, and TRIM.

```sh
nix build .#nixosConfigurations.services.config.system.build.toplevel --no-link
```
