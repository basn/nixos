# Battlestation

Flake output: `battlestation`.

Battlestation is the AMD desktop and gaming workstation. It runs Plasma 6,
the Mango/Noctalia session from `hjem/`, Steam with 32-bit graphics support,
PipeWire, and the CachyOS kernel with ZFS support. The optional VR
specialisation is retained in `configuration.nix`; it is currently disabled.

`cachyos-proton.nix` provides the local Proton helper and `opencode.nix`
defines the OpenCode integration.

## Configured services

- SDDM, Plasma 6, and the Mango/Noctalia session.
- NetworkManager, PipeWire/WirePlumber, and GNOME Keyring for Mango sessions.
- Steam, Gamescope support, and 32-bit graphics; the VR specialisation remains
  available but disabled.

```sh
nix build .#nixosConfigurations.battlestation.config.system.build.toplevel --no-link
```
