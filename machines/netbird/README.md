# Netbird

Flake output: `netbird`.

Netbird hosts the NetBird management, signal, and TURN services. It uses
Authentik for OIDC, Nginx and ACME for `netbird.basn.se`, SOPS-provided
service credentials, ZFS, and runs as a VMware guest.

`netbird.nix` defines the NetBird services; `sops.nix` declares the required
secret files.

## Configured services

- NetBird management, signal, and TURN (`coturn`) services.
- Nginx with ACME, OpenSSH, ZFS auto-scrub, and VMware guest support.
- NetBird service startup is gated on the required SOPS secret files.

```sh
nix build .#nixosConfigurations.netbird.config.system.build.toplevel --no-link
```
