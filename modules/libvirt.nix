{ lib, pkgs, config, ... }:
let
  cfg = config.basn.virtualisation.libvirt;
in
{
  options.basn.virtualisation.libvirt = {
    enable = lib.mkEnableOption "libvirt host module";

    user = lib.mkOption {
      type = lib.types.str;
      default = "basn";
      description = "User that should be added to libvirt/kvm groups.";
    };

    installTools = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install virt-manager and usbutils on the host.";
    };

    qemu = {
      runAsRoot = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "Optional override for virtualisation.libvirtd.qemu.runAsRoot.";
      };

      swtpm = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable swtpm support for libvirt guests.";
        };
      };
    };

    spiceUSBRedirection = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable SPICE USB redirection support.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation = {
      libvirtd = {
        enable = true;
        qemu =
          {
            swtpm.enable = cfg.qemu.swtpm.enable;
          }
          // lib.optionalAttrs (cfg.qemu.runAsRoot != null) { runAsRoot = cfg.qemu.runAsRoot; };
      };
      spiceUSBRedirection.enable = cfg.spiceUSBRedirection.enable;
    };

    environment.systemPackages = lib.optionals cfg.installTools (with pkgs; [
      virt-manager
      usbutils
    ]);

    users.groups = {
      libvirtd.members = [ cfg.user ];
      kvm.members = [ cfg.user ];
    };
  };
}
