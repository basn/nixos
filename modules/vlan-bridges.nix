{ lib, config, ... }:
let
  cfg = config.basn.network.bridgeLayout;

  mkVlanName = vlanId: "vlan${toString vlanId}";

  mkInterfaceDef =
    bridgeCfg:
    {
      useDHCP = bridgeCfg.useDHCP;
    }
    // lib.optionalAttrs (bridgeCfg.ipv4Addresses != [ ]) {
      ipv4.addresses = bridgeCfg.ipv4Addresses;
    }
    // lib.optionalAttrs (bridgeCfg.ipv6Addresses != [ ]) {
      ipv6.addresses = bridgeCfg.ipv6Addresses;
    };

  nativeBridgeDefs = lib.mapAttrs (_: _: { interfaces = [ cfg.uplink ]; }) cfg.nativeBridges;

  nativeInterfaceDefs = lib.mapAttrs (_: bridgeCfg: mkInterfaceDef bridgeCfg) cfg.nativeBridges;

  vlanDefs = lib.mapAttrs' (
    _: bridgeCfg:
    lib.nameValuePair (mkVlanName bridgeCfg.vlanId) {
      id = bridgeCfg.vlanId;
      interface = cfg.uplink;
    }
  ) cfg.vlanBridges;

  vlanBridgeDefs = lib.mapAttrs (_: bridgeCfg: { interfaces = [ (mkVlanName bridgeCfg.vlanId) ]; }) cfg.vlanBridges;

  vlanInterfaceDefs = lib.mapAttrs (_: bridgeCfg: mkInterfaceDef bridgeCfg) cfg.vlanBridges;

  bridgeDefs = nativeBridgeDefs // vlanBridgeDefs;
  interfaceDefs = nativeInterfaceDefs // vlanInterfaceDefs;
in
{
  options.basn.network.bridgeLayout = {
    enable = lib.mkEnableOption "host bridge and VLAN-backed bridge layout";

    disableBridgeNetfilter = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Disable bridge netfilter hooks to avoid host firewall filtering bridged VM traffic.";
    };

    uplink = lib.mkOption {
      type = lib.types.str;
      example = "eno1";
      description = "Host interface used as uplink and VLAN parent.";
    };

    nativeBridges = lib.mkOption {
      default = { };
      description = "Untagged bridges keyed by bridge name (for example br0).";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            useDHCP = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether to enable DHCP on this bridge.";
            };

            ipv4Addresses = lib.mkOption {
              type = lib.types.listOf lib.types.attrs;
              default = [ ];
              example = [
                {
                  address = "192.168.195.15";
                  prefixLength = 24;
                }
              ];
              description = "Optional static IPv4 addresses for this bridge.";
            };

            ipv6Addresses = lib.mkOption {
              type = lib.types.listOf lib.types.attrs;
              default = [ ];
              description = "Optional static IPv6 addresses for this bridge.";
            };
          };
        }
      );
    };

    vlanBridges = lib.mkOption {
      default = { };
      description = "VLAN-backed bridges keyed by bridge name (for example br7).";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            vlanId = lib.mkOption {
              type = lib.types.ints.positive;
              description = "VLAN ID to map into this bridge.";
            };

            useDHCP = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether to enable DHCP on this bridge.";
            };

            ipv4Addresses = lib.mkOption {
              type = lib.types.listOf lib.types.attrs;
              default = [ ];
              example = [
                {
                  address = "192.168.7.2";
                  prefixLength = 24;
                }
              ];
              description = "Optional static IPv4 addresses for this bridge.";
            };

            ipv6Addresses = lib.mkOption {
              type = lib.types.listOf lib.types.attrs;
              default = [ ];
              description = "Optional static IPv6 addresses for this bridge.";
            };
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    networking.vlans = lib.mkIf (cfg.vlanBridges != { }) vlanDefs;
    networking.bridges = bridgeDefs;
    networking.interfaces = interfaceDefs;

    boot.kernel.sysctl = lib.mkIf cfg.disableBridgeNetfilter {
      "net.bridge.bridge-nf-call-iptables" = 0;
      "net.bridge.bridge-nf-call-ip6tables" = 0;
      "net.bridge.bridge-nf-call-arptables" = 0;
    };
  };
}
