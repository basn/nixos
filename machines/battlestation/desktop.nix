{ pkgs, ... }:
{
  nixpkgs.overlays = [
    (_final: prev: {
      noctalia = prev.noctalia.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./noctalia-lockscreen-monitor-off.patch ];
        mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Dtests=disabled" ];
        doCheck = false;
      });
      noctalia-greeter = prev.noctalia-greeter.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./noctalia-greeter-pointer-speed.patch ];
      });
    })
  ];

  programs.umbriel.enable = true;

  hjem.users.basn.files.".config/noctalia/workspaces.toml".text = ''
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

  services = {
    displayManager.noctalia-greeter = {
      enable = true;
      settings.keyboard = {
        layout = "se";
        variant = "nodeadkeys";
      };
    };
    desktopManager.plasma6.enable = true;

    # This namespace is also consumed by graphical-desktop and Plasma on Wayland.
    xserver.xkb = {
      layout = "se";
      variant = "nodeadkeys";
      model = "pc105";
    };
  };

  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [ meslo-lgs-nf ];
  };

  environment.variables.NIXOS_OZONE_WL = "1";
  environment.systemPackages = [ pkgs.volantes-cursors ];
}
