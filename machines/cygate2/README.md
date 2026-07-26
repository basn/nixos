# Cygate2

Flake output: `nixos-sov2`; runtime hostname: `nixos-sov2`.

Cygate2 is the second VMware ZFS replication receiver. Like Cygate, it runs
Uptime Kuma behind Nginx, scheduled ZFS scrubs, and a restricted `syncoid`
receiver account for backup replication.

## Configured services

- Uptime Kuma and its Nginx reverse proxy.
- OpenSSH, ZFS auto-scrub, VMware guest support, and the `zfs-permissions`
  one-shot service for the replication receiver.

Service definitions are in `services/`; hardware settings are in
`hardware-configuration.nix`.

```sh
nix build .#nixosConfigurations.nixos-sov2.config.system.build.toplevel --no-link
```
