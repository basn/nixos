{
  lib,
  pkgs,
  ...
}:
let
  enableVrSpecialisation = false;

  monadoPimax = pkgs.monado.overrideAttrs (oldAttrs: {
    version = "25.1.0-pimax-16792a6";
    src = pkgs.fetchFromGitLab {
      domain = "gitlab.freedesktop.org";
      owner = "Coreforge";
      repo = "monado";
      rev = "16792a6f26210faca082d192a8fa9fbf625ab1d9";
      hash = "sha256-M7bjfHS4h0GQ/77PuIxEVvhFZl4dDPVas19/oSfoGCk=";
    };
    patches = [ ];
    meta = oldAttrs.meta // {
      description = "Open source XR runtime with Coreforge Pimax P2 support";
    };
  });

  pimaxDistortion = pkgs.fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "othello7";
    repo = "pimax-distortion";
    rev = "a64c75ed9f4f3bd71847e6daa4b882e38bb5cb07";
    hash = "sha256-33cimiRQgJkL9xj7Y7cJgiCdRXGqFG9qqdNvx4gm5i8=";
  };

  vrKernelPatches = [
    {
      name = "pimax-non-desktop-edid-quirks";
      patch = pkgs.fetchurl {
        url = "https://gist.githubusercontent.com/TayouVR/60e3ee5f95375827a66a8898bea02bec/raw/c85135c8d8821ebb2fa85629d837a41de57e12ef/pimax.patch";
        hash = "sha256-xD8mUZne3MDFDt4jstsBv5bG7fWSejV4LEAKB3GWdAY=";
      };
    }
    {
      name = "pimax-edid-checksum-fixup";
      patch = pkgs.fetchurl {
        url = "https://gist.githubusercontent.com/Coreforge/59ed3548427c999273ec012002461eab/raw/f70df3afd5cccbfc6fb34ef805db41d00dbf4770/ps0002-drm-edid-fix-checksum-errors-in-Pimax-HMD-EDIDs.patch";
        hash = "sha256-faggU9KLVydvdQR8m9V7SUQnwtXs+h9IpNv9BS64qZU=";
      };
    }
  ];

  vrUdevRules = ''
    # Allow Monado's Pimax driver to access P2-series headset control HID.
    SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="0101", MODE="0660", GROUP="input"
    KERNEL=="hidraw*", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="0101", MODE="0660", GROUP="input"
  '';

  vrOpenvrConfig = pkgs.writeText "openvrpaths.vrpath" (
    builtins.toJSON {
      version = 1;
      jsonid = "vrpathreg";
      external_drivers = null;
      config = [ "/home/basn/.local/share/Steam/config" ];
      log = [ "/home/basn/.local/share/Steam/logs" ];
      runtime = [ "${pkgs.xrizer}/lib/xrizer" ];
    }
  );

  vrSteamPackage = pkgs.steam.override {
    extraProfile = ''
      export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1
      unset TZ
    '';
  };
in
{
  specialisation = lib.mkIf enableVrSpecialisation {
    vr.configuration = {
      boot.kernelPatches = vrKernelPatches;
      services = {
        monado = {
          enable = true;
          package = monadoPimax;
          defaultRuntime = true;
        };
        udev.extraRules = vrUdevRules;
      };
      systemd.user.services.monado.environment = {
        STEAMVR_LH_ENABLE = "1";
        IPC_EXIT_WHEN_IDLE = "1";
        PIMAX_HID_RETRY_COUNT = "10";
      };
      hjem.users.basn.files.".config/openvr/openvrpaths.vrpath".source = vrOpenvrConfig;
      hjem.users.basn.files.".config/pimax/meshes".source = "${pimaxDistortion}/meshes";
      environment.systemPackages = [ pkgs.xrizer ];
      programs.steam.package = vrSteamPackage;
    };
  };
}
