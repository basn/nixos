{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs = {
    umbriel.enable = true;
    steam.enable = false;
  };

  hjem.users.basn.files = {
    # Let Umbriel discover connected displays instead of inheriting the desktop's
    # fixed DP modes and workspace placement. Defaults use dynamic workspaces.
    ".config/umbriel/outputs.toml".source = lib.mkForce (
      pkgs.writeText "laptop-umbriel-outputs.toml" ''
        # Preferred modes, automatic placement, and dynamic workspaces.
        # No connector-specific rules: support the internal panel and docking.
      ''
    );
    # Keep the laptop's existing Swedish layout, including dead keys, in every
    # session while retaining the other shared input settings.
    ".config/umbriel/input.toml".source = lib.mkForce (
      (pkgs.formats.toml { }).generate "laptop-umbriel-input.toml" (
        lib.recursiveUpdate (builtins.fromTOML (builtins.readFile ../../hjem/configs/umbriel/input.toml)) {
          input.keyboard = {
            inherit (config.services.xserver.xkb) layout variant;
          };
        }
      )
    );
    ".config/noctalia/workspaces.toml".text = ''
      [widget.workspaces]
      type = "taskbar"
      group_by_workspace = true
      workspace_group_content = "icons"
      workspace_group_capsule = false
      only_active_workspace = false
      hide_empty_workspaces = false
      show_workspace_label = true
      workspace_label_placement = "inside"
      group_single_icon_per_app = true
      icon_scale = 1.125
    '';
  };

  services = {
    desktopManager = {
      plasma6 = {
        enable = true;
      };
    };
    displayManager = {
      noctalia-greeter = {
        enable = true;
        settings.keyboard = {
          inherit (config.services.xserver.xkb) layout variant;
        };
      };
    };
  };
  environment.variables.NIXOS_OZONE_WL = "1";
  environment.systemPackages = with pkgs; [
    kdePackages.kcalc
    kdePackages.kcharselect
    kdePackages.kcolorchooser
    kdePackages.kolourpaint
    kdePackages.ksystemlog
    kdePackages.partitionmanager
    haruna
    playerctl
    volantes-cursors
    wayland-utils
    wl-clipboard
  ];
}
