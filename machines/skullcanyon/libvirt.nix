{ pkgs, ... }:
{
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        runAsRoot = false;
        swtpm = {
          enable = true;
        };
      };
    };
    spiceUSBRedirection = {
      enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    virt-manager
    usbutils
  ];

  users.users.basn = {
    extraGroups = [
      "libvirtd"
      "kvm"
    ];
  };
}
