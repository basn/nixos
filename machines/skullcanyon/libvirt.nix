{ pkgs, ... }:
{
  virtualisation = {
    libvirtd = {
      enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    virt-manager
    usbutils
  ];

  users.users.basn = {
    extraGroups = [ "libvirtd" ];
  };
}
