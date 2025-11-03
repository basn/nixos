{ pkgs , ... }:
{
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection = {
      enable = true;
    };
  };
  users = {
    groups = {
      libvirtd.members = [ "basn" ];
      kvm.members = [ "basn" ];
    };
  };
}
