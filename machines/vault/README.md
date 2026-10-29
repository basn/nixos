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

## Ethernet reliability mitigation

The October 29, 2026 report at
`/var/log/network-diagnostics/network-diagnostics-vault-20261029T070646Z.log`
recorded carrier loss on `enp1s0` from 03:41:01 to 08:06:50 CET. DHCP recovered
normally after carrier returned. NIC runtime-suspended time (15,940.797 seconds)
closely matched the outage (15,949 seconds); September 11 showed a similar
pattern. Both links recovered seconds after read-only diagnostics began.
Diagnostic queries may have resumed the NIC, but the restoring operation and
initial carrier-loss trigger are not proven; cable/switch or driver faults
remain possible. EEE was already disabled and `pcie_aspm=off` was already in use;
PCI runtime PM is a separate mechanism.

The host-local mitigation retains PowerTOP auto-tuning through
`powertop.service`. A targeted udev add/change rule sets PCI `power/control=on`
for only `0000:01:00.0`, matching Intel vendor `0x8086` and I226-V device
`0x125c`. After every successful service auto-tune, its `ExecStartPost` hook
verifies that identity and that `power/control` exists, then restores only this
NIC to `on`. Other auto-tuning is retained, including on the second NIC; DHCP,
DNS, NetBird, and link negotiation settings are unchanged.

PowerTOP 2.15 has no native device exclusion, so there is a short transient
window in which auto-tuning can set this NIC to `auto` before the hook restores
`on`. This is a mitigation, not a guarantee against any runtime suspend. An
identity mismatch, missing control, or failed write fails the hook and service
with an error; there is no fallback broad override. If auto-tuning itself fails,
the post-start hook does not run and partial tuning may remain. Run PowerTOP
only through its service, never manually: direct invocation bypasses the hook
and can undo the NIC policy. The service is oneshot with `RemainAfterExit=yes`;
starting an already-active service does not run auto-tuning again.

The carrier watchdog checks roughly every minute, cycles `enp1s0` after at
least 300 seconds without carrier, and limits retries to once per 900 seconds.
Previously, systemd deleted its runtime directory after every oneshot: 230
checks during the October outage each restarted the countdown. Setting
`RuntimeDirectoryPreserve=yes` retains threshold/cooldown timestamps between
runs while allowing the oneshot to exit and the timer to fire again. State is
still cleared on reboot, or by the script when carrier is healthy.

Review the runtime-PM workaround after NIC firmware, kernel/igc, or hardware
updates, and reassess the hook when updating PowerTOP/nixpkgs. Remove the NIC
udev rule and post-start override only after controlled testing shows
reliable carrier recovery with runtime PM enabled. Recheck the PCI match after
hardware/layout changes. Keep the watchdog state-preservation fix independently
of that workaround.

Repository changes and builds do not apply this mitigation to a running host.
Installing a udev rule does not itself apply it to an already enumerated device,
and a build does not execute the service hook. An explicitly
authorized deployment and reboot, or separately authorized targeted live-policy
application, is required. Before deploying, check the auto-upgrade service/timer
for races. Afterwards verify successful `powertop.service` auto-tuning and its
post-start hook, PCI `power/control=on`, watchdog timer activity/state retention,
and normal carrier/DHCP operation.
Live outage/recovery testing must be separately authorized; a build alone does
not prove the recurring fault is cured.
