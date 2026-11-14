# Battlestation

Flake output: `battlestation`.

Battlestation is the AMD desktop and gaming workstation. It runs Wayland
sessions for Plasma 6 and Umbriel/Noctalia, Steam with 32-bit graphics support,
PipeWire, and the CachyOS kernel with ZFS support. The optional VR
specialisation is retained in `specialisation.nix`; it is currently disabled.

Kernel Rust support is temporarily disabled: the pinned kernel fails BTF
generation for Rust modules (`rnull_mod` and `rcpufreq_dt`). This host does not
require those drivers; CachyOS BORE/ThinLTO, x86-64-v3, BTF, and ZFS remain
enabled. Remove the workaround once upstream Rust module BTF generation works.

`audio.nix` contains PipeWire and device rules, `desktop.nix` contains the
Wayland desktop and greeter setup, `cachyos-proton.nix` provides the local
Proton helper, and `opencode.nix` defines the OpenCode integration.
The OpenCode configuration and certificate are deployed through the shared
`hjem/tooling.nix` module, while this host alone provides the OpenCode package,
helper commands, and SOPS-backed MCP environment.

## Hermes client

`oc` exports the mode-0400 SOPS `opencode-mcp-env` file, now including
`HERMES_API_KEY` for the native remote provider. After an authorized deployment,
use `oc --standalone` when the V2 shared background server was started without
that environment: exporting a key in a later client does not update an existing
server's environment. No background service is restarted by this change.
Use `@hermes` or explicitly ask Astra to delegate remote work to Hermes.
See [remote authority and prerequisites](../hermes/README.md#opencode-api).

Laptop receives the shared JSON but has no corresponding SOPS environment or
`oc` wrapper. Before using Hermes there, securely provision the same
`HERMES_API_KEY` into its OpenCode server environment (or an authorized provider
connection); do not copy it into the JSON or the Nix store.

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

## Boot console

Bootvine replaces Plymouth with a live systemd dependency tree on tty12 during
the systemd initrd, stage 2, and shutdown. Its default ANSI colors use the
OneDarkPro `onedark_dark` terminal palette, matching Neovim: black background
(`#000000`) and foreground `#abb2bf`. `console.colors` also applies this palette
to all virtual consoles. Quiet/log parameters, the kernel, ZFS credential
requests, and the greeter are unchanged.

Keep a known-good boot generation before trying this on hardware. Real boot
has not been tested: check encrypted ZFS unlock through systemd-ask-password,
the Swedish console keymap (including password punctuation), wrong-password
retry, handoff to the Noctalia greeter, and the shutdown display. Build success
alone does not verify the ZFS password interaction or console handoff.

```sh
nix build .#nixosConfigurations.battlestation.config.system.build.toplevel --no-link
```
