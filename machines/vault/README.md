# Vault

Flake output: `vault`.

Vault is a ZFS storage and backup host. It provides Samba and rsync access,
ZnapZend replication, a dedicated backup user with ZFS permissions, SOPS
secret declarations, scheduled ZFS scrubs, and automatic upgrades.

Host-specific backup and sharing definitions are in `services/`.

## Configured services

- Samba and rsync for storage access.
- ZnapZend replication, OpenSSH, ZFS auto-scrub and TRIM, and automatic
  upgrades.
- The `zfs-permissions` one-shot service provisions delegated backup access.

```sh
nix build .#nixosConfigurations.vault.config.system.build.toplevel --no-link
```
