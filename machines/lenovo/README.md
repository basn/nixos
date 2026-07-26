# Lenovo

Flake output: `lenovo`.

Lenovo is an Intel ZFS and libvirt host. It provides native and VLAN-backed
bridges through the local bridge module, stores virtual-machine images under
`osdisk/vms`, and runs OpenSSH, ZFS scrubs, automatic upgrades, and `nh`
cleanup.

## Configured services

- libvirtd/QEMU with automatic directory-pool management.
- OpenSSH, ZFS auto-scrub, automatic NixOS upgrades, and scheduled `nh`
  cleanup.
- Native and VLAN-backed bridges supplied by `modules/vlan-bridges.nix`.

```sh
nix build .#nixosConfigurations.lenovo.config.system.build.toplevel --no-link
```
