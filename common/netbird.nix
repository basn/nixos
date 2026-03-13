{ ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      netbird-ui = prev.netbird-ui.overrideAttrs (old: {
        postInstall =
          (old.postInstall or "")
          + ''
            substituteInPlace "$out/share/applications/netbird.desktop" \
              --replace-fail 'Exec=netbird-ui' "Exec=$out/bin/netbird-ui"
          '';
      });
    })
  ];

  services = {
    netbird = {
      enable = true;
    };
  };
}
