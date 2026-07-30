# Skullcanyon

Flake output: `skullcanyon`.

Skullcanyon is an Intel ZFS and libvirt host. It provides native and
VLAN-backed bridges, stores VM images under `osdisk/vms`, and runs OpenSSH,
ZFS scrubs, automatic upgrades, and `nh` cleanup.

## Configured services

- libvirtd/QEMU with automatic directory-pool management.
- OpenSSH, ZFS auto-scrub, automatic upgrades, and scheduled `nh` cleanup.
- Native and VLAN-backed bridges supplied by `modules/vlan-bridges.nix`.

```sh
nix build .#nixosConfigurations.skullcanyon.config.system.build.toplevel --no-link
```
