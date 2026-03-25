{ config, pkgs, ... }:
let
  vgpuRunfile = builtins.path {
    path = /var/lib/nvidia-vgpu/NVIDIA-Linux-x86_64-580.126.09-grid.run;
    name = "NVIDIA-Linux-x86_64-580.126.09-grid.run";
  };

  vgpuDriver = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "580.126.09";
    url = "file://${vgpuRunfile}";
    sha256_64bit = "sha256-4SyHt0toz95T80LExm4G0Ki7S0w07Jt4pJnmf/xHkD0=";

    # GRID/vGPU guest package: keep build inputs minimal.
    useSettings = false;
    usePersistenced = false;
    useFabricmanager = false;
    postInstall = ''
      if [ -n "$bin" ] && [ -e nvidia-gridd ]; then
        install -Dm755 nvidia-gridd "$bin/bin/nvidia-gridd"
        install -Dm755 nvidia-gridd "$bin/origBin/nvidia-gridd"
        patchelf --interpreter "$(cat "$NIX_CC/nix-support/dynamic-linker")" \
          --set-rpath "$out/lib:$libPath" \
          "$bin/bin/nvidia-gridd"
      fi
    '';
  };
in
{
  nixpkgs.config.nvidia.acceptLicense = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  boot.blacklistedKernelModules = [ "nouveau" ];

  hardware = {
    graphics = {
      enable = true;
    };
    nvidia = {
      package = vgpuDriver;
      open = false;
      gsp.enable = false;
      nvidiaSettings = false;
      nvidiaPersistenced = false;
    };
  };

  # Start NVIDIA GRID licensing daemon explicitly; NixOS has no dedicated gridd module.
  systemd.services.nvidia-gridd = {
    description = "NVIDIA GRID Licensing Daemon";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    unitConfig = {
      ConditionPathExists = "/var/lib/nvidia-vgpu/client_configuration_token.tok";
    };
    serviceConfig = {
      Type = "forking";
      PIDFile = "/run/nvidia-gridd/nvidia-gridd.pid";
      ExecStartPre = [
        "${pkgs.coreutils}/bin/install -d -m 0755 /etc/nvidia/ClientConfigToken"
        "${pkgs.coreutils}/bin/install -m 0644 /var/lib/nvidia-vgpu/client_configuration_token.tok /etc/nvidia/ClientConfigToken/client_configuration_token.tok"
        "${pkgs.coreutils}/bin/install -d -m 0755 /etc/nvidia"
        "${pkgs.runtimeShell} -lc 'test -e /etc/nvidia/gridd.conf || ${pkgs.coreutils}/bin/touch /etc/nvidia/gridd.conf'"
        "${pkgs.coreutils}/bin/install -d -m 0755 /var/lib/nvidia/GridLicensing"
        "${pkgs.runtimeShell} -lc 'if [ -f /run/nvidia-gridd/nvidia-gridd.pid ]; then pid=$(cat /run/nvidia-gridd/nvidia-gridd.pid 2>/dev/null || true); if [ -n \"$pid\" ] && ! kill -0 \"$pid\" 2>/dev/null; then rm -f /run/nvidia-gridd/nvidia-gridd.pid; fi; fi'"
      ];
      ExecStart = "${config.hardware.nvidia.package.bin}/bin/nvidia-gridd";
      Restart = "always";
      RestartSec = 5;
    };
  };
}
