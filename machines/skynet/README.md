# Skynet

Fresh x86_64 VMware server with the normal shared server baseline, using the
existing locked `nixpkgs-unstable-small` input and no application extras. Its initial
`system.stateVersion` is `26.11`; keep it unchanged after installation.

## Provisioning assumptions

Disk preparation is not required before a Git push. Provision storage separately
before installing; this configuration does not partition disks or create pools,
datasets, or filesystems:

- The confirmed fresh VM disk is `/dev/sda` (1 TB), intended for a 1 GiB EFI
  partition and ZFS on the remainder. Actual disk preparation is not verified.
- Boot the VM and installer in EFI mode. systemd-boot uses the EFI system
  partition at `/boot`; installation registers its EFI boot entry in firmware.
- Create the `osdisk` ZFS pool with datasets `osdisk/root`, `osdisk/nix`,
  `osdisk/var`, and `osdisk/home`, each using `mountpoint=legacy` for the declared
  NixOS filesystem mounts. Before installation, mount them at `/mnt`, `/mnt/nix`,
  `/mnt/var`, and `/mnt/home`, respectively.
- Create a FAT32 EFI system partition (1 GiB recommended) with **filesystem label
  `SKYNET-EFI`** (not merely a GPT partition label), mounted at `/mnt/boot` before
  installation. The installed system mounts it at `/boot`.
- ZFS discovers devices through `/dev/disk/by-path`; root pool force-import is
  disabled. The host has its own ZFS host ID, `5018a94f`.
- There is no swap, backup pool, or inherited source-host disk UUID.
- After installation and before first boot, cleanly unmount the target
  filesystems and export only `osdisk`, not any installer pools. With
  `forceImportRoot = false` and a target host ID different from the installer's,
  a clean export is needed for the target to import the pool normally.

The confirmed NIC is `ens33`. It uses `10.136.48.5/24`, gateway `10.136.48.1`, and DNS
`8.8.8.8`. DHCP and IPv6 are disabled. The firewall allows SSH and the normal
NetBird client traffic, plus monitoring ports 9100 and 9633 only from collector
`100.86.89.177` over `wt0`. There is no NAT or forwarding configuration.

## Administration and builds

NVIDIA runs headless with the open kernel module and proprietary userspace;
X, a display manager, and the NVIDIA settings GUI are disabled. The NVIDIA H100
must be passed through to the VM. No CUDA applications are added. CPU and RAM
are not known. Secure Boot is not configured here.

The normal user `basn` inherits `common/users.nix`, including its public SSH
keys, Fish shell, user packages, and `wheel` membership. Those existing key
holders receive passwordless sudo. SSH
password and keyboard-interactive authentication and root SSH login are
disabled. No root password is provisioned; retain console access during setup.

The shared baseline includes the normal tools, NVF, locale/time settings,
trusted Attic cache, cleanup, SSH, NetBird, and node/smartctl exporters. VMware
guest support, ZFS scrubbing, and automatic upgrades are enabled. SOPS secret
provisioning, ZFS mail, and upgrade webhook notifications are deferred. The SOPS
module remains available for shared option compatibility, but no secrets are
configured; its CLI remains a baseline tool. The smartd role remains disabled.
No application services, runners, audit agents, nginx, Kuma, syncoid, backup
jobs, NAT, or host-specific resource tuning are added.

## Setup blockers and enrollment

SOPS authorization is not required for installation now. To enable notifications
later, authorize Skynet's persistent host key and public age recipient under
`.sops.yaml`, rewrap the shared files below for that recipient, then enable the
notification roles:

- `secrets/zfs.yaml`, key `password`, for ZFS mail (`/run/secrets/zfs`).
- `secrets/webhook.yaml`, key `nixos-upgrade-webhook`, for upgrade notifications
  (`/run/secrets/nixos-upgrade-webhook`).

These secrets are not declared or consumed by the current configuration. No host
keys or recipients are created and no secrets are rewrapped by this change.

NetBird is enabled but requires manual enrollment with `https://netbird.basn.se`.
Exporter configuration and firewall rules alone do not enroll the host in
central monitoring; collector-side scrape registration remains to be done
separately after enrollment. No collector configuration is changed here.

The host automatically enters the flake-derived CI build matrix. Automatic
upgrades follow the public `git+https://github.com/basn/nixos` configuration
nightly, with the shared randomized delay and no automatic reboot. Publish the
Skynet configuration there before relying on upgrades; unpublished local edits
are not used by the timer.

Build from the repository root after the new files are tracked:

```sh
nix build .#nixosConfigurations.skynet.config.system.build.toplevel --no-link --no-write-lock-file
```

Building does not provision storage or activate the configuration on a VM.
