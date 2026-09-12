{ ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      noctalia = prev.noctalia.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./noctalia-lockscreen-monitor-off.patch ];
        mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Dtests=disabled" ];
        doCheck = false;
      });
    })
  ];

  programs.umbriel.enable = true;
}
