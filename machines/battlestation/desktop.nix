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
