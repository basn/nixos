# Laptop

Flake output: `laptop`.

Laptop is the portable Plasma 6 desktop. It uses NetworkManager with Wi-Fi
power saving, PipeWire audio, Intel microcode, ZFS, and the shared `hjem/`
desktop environment.

## Configured services

- Plasma 6 and SDDM, with the shared `hjem/` user environment.
- NetworkManager, PipeWire/WirePlumber, RTKit, power management, and Powertop.
- OpenSSH and ZFS support.

`plasma6.nix` contains the desktop-specific settings; generated hardware
settings remain in `hardware-configuration.nix`.

```sh
nix build .#nixosConfigurations.laptop.config.system.build.toplevel --no-link
```
