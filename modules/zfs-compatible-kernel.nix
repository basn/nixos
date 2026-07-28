{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.basn.boot.useLatestZfsCompatibleKernel;
  zfsCompatibleKernelPackages = lib.filterAttrs (
    name: kernelPackages:
    (builtins.match "linux_[0-9]+_[0-9]+" name) != null
    && (builtins.tryEval kernelPackages).success
    && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
  ) pkgs.linuxKernel.packages;
  latestKernelPackage = lib.last (
    lib.sort (a: b: lib.versionOlder a.kernel.version b.kernel.version) (
      builtins.attrValues zfsCompatibleKernelPackages
    )
  );
in
{
  options.basn.boot.useLatestZfsCompatibleKernel = lib.mkEnableOption "the latest ZFS-compatible kernel package set";

  config = lib.mkIf cfg {
    boot.kernelPackages = latestKernelPackage;
  };
}
