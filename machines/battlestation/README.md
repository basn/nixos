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

- Noctalia Greeter on greetd, Plasma 6, and the Umbriel/Noctalia session.
- NetworkManager, PipeWire/WirePlumber, and GNOME Keyring for Umbriel sessions.
- Steam, Gamescope support, and 32-bit graphics; the VR specialisation remains
  available but disabled.

```sh
nix build .#nixosConfigurations.battlestation.config.system.build.toplevel --no-link
```
