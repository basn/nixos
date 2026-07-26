# Cygate

Flake output: `nixos-sov`; runtime hostname: `nixos-sov`.

Cygate is a VMware guest and ZFS replication receiver. It runs Uptime Kuma
behind Nginx, performs ZFS scrubs, and grants the `syncoid` user the required
receive permissions for incoming backups.

## Configured services

- Uptime Kuma and its Nginx reverse proxy.
- OpenSSH, ZFS auto-scrub, VMware guest support, and the `zfs-permissions`
  one-shot service for the replication receiver.

Service definitions are in `services/`; hardware settings are in
`hardware-configuration.nix`.

```sh
nix build .#nixosConfigurations.nixos-sov.config.system.build.toplevel --no-link
```
