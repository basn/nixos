# Battlestation

Flake output: `battlestation`.

Battlestation is the AMD desktop and gaming workstation. It runs Wayland
sessions for Plasma 6 and Umbriel/Noctalia, Steam with 32-bit graphics support,
PipeWire, and the CachyOS kernel with ZFS support. The optional VR
specialisation is retained in `specialisation.nix`; it is currently disabled.

`audio.nix` contains PipeWire and device rules, `desktop.nix` contains the
Wayland desktop and greeter setup, `cachyos-proton.nix` provides the local
Proton helper, `ollama.nix` configures the local Ollama service, and
`opencode.nix` defines the OpenCode integration.
The OpenCode configuration and certificate are deployed through the shared
`hjem/tooling.nix` module, while this host alone provides the OpenCode package,
helper commands, and SOPS-backed MCP environment.

## Configured services

Umbriel defaults to dwindle with dynamic workspaces on both monitors: unused
workspaces are pruned and a trailing empty workspace remains available.
The persistent first workspace on DP-2 is `discord`, followed by positional
labels `2`, `3`, and so on; this does not route Discord windows automatically.
Numeric workspace shortcuts beyond the existing positions clamp to the last
workspace rather than creating arbitrary positions. Master layout settings
remain available when switching layouts.

Noctalia's workspace widget is a taskbar grouped by workspace, showing app icons
on both active and inactive workspaces with one icon per app. Empty workspaces
remain visible. Labels are always shown inside groups, including occupied ones;
the named workspace stays `discord` rather than becoming a numeric label.
Workspace group backgrounds and outlines are disabled; icons, labels, and grouping
are retained.
The host-local Hjem-managed `~/.config/noctalia/workspaces.toml` requests
`icon_scale = 1.125` (about 18px from a 16px base, subject to bar fit); bar thickness
is unchanged.
UI settings in `~/.local/state/noctalia/settings.toml` merge last and can override
these declarative defaults.

- Noctalia Greeter on greetd, Plasma 6, and the Umbriel/Noctalia session.
- NetworkManager, PipeWire/WirePlumber, and GNOME Keyring for Umbriel sessions.
- Steam, Gamescope support, and 32-bit graphics; the VR specialisation remains
  available but disabled.

```sh
nix build .#nixosConfigurations.battlestation.config.system.build.toplevel --no-link
```
