# Laptop

Flake output: `laptop`.

Laptop is the portable Umbriel/Noctalia desktop, with Plasma 6 available as a
fallback session in the Noctalia greeter (replacing SDDM). Select Umbriel or
Plasma at login. It uses NetworkManager with Wi-Fi
power saving, PipeWire audio, Intel microcode, ZFS, and the shared `hjem/`
desktop environment.

## Configured services

- Umbriel and Noctalia, with the shared `hjem/` user environment, workspace
  taskbar, Volantes cursor, and Wayland application environment.
- Noctalia greeter and Plasma 6 fallback; Steam is explicitly disabled.
- Plymouth with the `nixos-bgrt` theme and quiet boot, retaining the laptop's
  touchpad module blacklist and ZFS encryption credential request.
- NetworkManager, PipeWire/WirePlumber, RTKit, power management, and Powertop.
- OpenSSH and ZFS support.

`plasma6.nix` contains the desktop-specific settings; generated hardware
settings remain in `hardware-configuration.nix`.

Laptop-local Hjem overrides use Umbriel's automatic output discovery, preferred
modes, automatic positioning, and dynamic workspaces instead of battlestation's
DP-1/DP-2 modes and Discord workspace placement. Run `umbriel outputs` inside a
session before adding panel scaling or docking-specific rules. Displays without
a preferred mode or identity may need an explicit output rule.

The existing Swedish layout with dead keys is retained for Plasma, Umbriel, and
the greeter; battlestation uses `nodeadkeys`. Shared media bindings have
`playerctl` available. Battlestation's greeter pointer-speed and lockscreen
Escape-to-power-off patches are intentionally not copied.

After deployment, test both login sessions, locking/unlocking, suspend/resume,
touchpad behavior, media keys, external-display hotplug, and Plymouth's ZFS
unlock prompt. Panel scaling and brightness/lid behavior may need laptop-specific
tuning after testing on the hardware.

```sh
nix build .#nixosConfigurations.laptop.config.system.build.toplevel --no-link
```
