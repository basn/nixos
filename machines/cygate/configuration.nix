{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./services/kuma.nix
    ./services/nginx.nix
    ./services/syncoid.nix
  ];

  boot = {
    # Keep ARC bounded so runner builds cannot force the 32 GiB VM into
    # recursive ZFS memory reclaim.
    extraModprobeConfig = "options zfs zfs_arc_max=8589934592";
    zfs = {
      extraPools = [
        "osdisk"
        "backup"
      ];
      devNodes = "/dev/disk/by-path";
      forceImportRoot = false;
    };
    loader.grub = {
      enable = true;
      zfsSupport = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
      mirroredBoots = [
        {
          devices = [ "nodev" ];
          path = "/boot";
        }
      ];
    };
    kernel = {
      sysctl."net.ipv4.ip_forward" = 1;
    };
  };
  networking = {
    interfaces = {
      eth0.ipv4.addresses = [
        {
          address = "10.140.12.5";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = "10.140.12.1";
    nameservers = [ "8.8.8.8" ];
    hostId = "e5dafd0b";
    enableIPv6 = false;
    hostName = "nixos-sov";
    timeServers = [ "ntp1.sp.se" ];
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
        443
      ];
      checkReversePath = "loose";
    };
    nat = {
      enable = true;
      externalInterface = "eth0";
      internalInterfaces = [ "wt0" ];
    };
  };
  virtualisation.vmware.guest.enable = true;
  sops = {
    defaultSopsFile = ./secrets/runner.yaml;
    secrets.github-actions-runner-token = {
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };
  services.github-runners.nixos-sov = {
    enable = true;
    url = "https://github.com/basn/nixos";
    tokenFile = config.sops.secrets.github-actions-runner-token.path;
    tokenType = "access";
    extraLabels = [
      "nix-nightly"
      "nixos"
    ];
    # Workflow commands not already provided by the github-runners module.
    extraPackages = [
      pkgs.attic-client
      pkgs.curl
      pkgs.getent
      pkgs.openssh
      pkgs.procps
    ];
  };
  nix.settings = {
    max-jobs = 1;
    cores = 8;
  };
  systemd.services.nix-daemon.serviceConfig = {
    CPUQuota = "800%";
    Nice = 10;
    # nix-daemon.nix sets best-effort; intentionally lower build I/O priority.
    IOSchedulingClass = lib.mkForce "idle";
    MemoryHigh = "22G";
    MemoryMax = "26G";
    OOMPolicy = "stop";
  };
  # Dedicated non-ZFS VMware disk, labelled during provisioning.
  swapDevices = [ { device = "/dev/disk/by-label/nixos-sov-swap"; } ];
  system.stateVersion = "24.05";
}
