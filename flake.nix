{
  description = "Basn flake for machines.";
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs?ref=nixos-26.05-small";
    };
    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs?ref=nixos-unstable";
    };
    nixpkgs-unstable-small = {
      url = "github:nixos/nixpkgs?ref=nixos-unstable-small";
    };
    sops_nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vpn-confinement = {
      url = "github:Maroka-chan/VPN-Confinement";
    };
    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel";
    };
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{ self, ... }:
    let
      system = "x86_64-linux";
      lib = inputs.nixpkgs.lib;
      mkPkgs =
        nixpkgsInput:
        import nixpkgsInput {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
      unstablePkgs = mkPkgs inputs.nixpkgs-unstable;
      unstableSmall = mkPkgs inputs.nixpkgs-unstable-small;
      mkHost =
        {
          nixpkgsLib ? lib,
          modules,
          includeCommon ? true,
          includeNetbird ? true,
          includeMonitoring ? true,
          includeZfsRole ? false,
          includeAutoUpgradeRole ? false,
          includeSmartdRole ? false,
          includeDeployUser ? true,
          extraSpecialArgs ? { },
        }:
        nixpkgsLib.nixosSystem {
          inherit system;
          modules = [
            { boot.zfs.forceImportRoot = false; }
            ./common/openssh.nix
            ./modules/zfs-compatible-kernel.nix
          ]
          ++ lib.optionals includeDeployUser [ ./modules/deploy-rs-user.nix ]
          ++ lib.optionals includeCommon [ ./common/common.nix ]
          ++ lib.optionals (includeCommon && includeNetbird) [ ./common/netbird.nix ]
          ++ lib.optionals (includeCommon && includeMonitoring) [ ./common/monitoring-exporters.nix ]
          ++ lib.optionals includeZfsRole [ ./common/zfs.nix ]
          ++ lib.optionals includeAutoUpgradeRole [ ./common/auto-upgrade.nix ]
          ++ lib.optionals includeSmartdRole [ ./common/smartd.nix ]
          ++ modules;
          specialArgs = {
            inherit
              inputs
              self
              system
              ;
          }
          // extraSpecialArgs;
        };
      baseModules = [
        inputs.sops_nix.nixosModules.sops
        inputs.nvf.nixosModules.default
      ];
    in
    {
      nixosConfigurations = {
        bandit = mkHost {
          includeZfsRole = true;
          includeAutoUpgradeRole = true;
          includeSmartdRole = true;
          extraSpecialArgs = { inherit unstablePkgs; };
          modules = baseModules ++ [
            inputs.vpn-confinement.nixosModules.default
            ./machines/bandit/configuration.nix
          ];
        };
        vault = mkHost {
          includeZfsRole = true;
          includeAutoUpgradeRole = true;
          includeSmartdRole = true;
          extraSpecialArgs = { inherit unstablePkgs; };
          modules = baseModules ++ [ ./machines/vault/configuration.nix ];
        };
        laptop = mkHost {
          nixpkgsLib = inputs.nixpkgs-unstable.lib;
          extraSpecialArgs = { inherit unstableSmall; };
          modules = baseModules ++ [
            ./machines/laptop/configuration.nix
            inputs.hjem.nixosModules.default
            ./hjem/default.nix
          ];
        };
        battlestation = mkHost {
          nixpkgsLib = inputs.nixpkgs-unstable.lib;
          includeZfsRole = true;
          includeAutoUpgradeRole = true;
          includeSmartdRole = true;
          extraSpecialArgs = { inherit unstableSmall; };
          modules = baseModules ++ [
            ./machines/battlestation/configuration.nix
            inputs.hjem.nixosModules.default
            ({ ... }: { nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ]; })
            ./hjem/default.nix
          ];
        };
        services = mkHost {
          includeZfsRole = true;
          includeAutoUpgradeRole = true;
          extraSpecialArgs = { inherit unstablePkgs unstableSmall; };
          modules = [
            inputs.sops_nix.nixosModules.sops
            ./machines/services/configuration.nix
            inputs.nvf.nixosModules.default
          ];
        };
        nixos-sov = mkHost {
          includeZfsRole = true;
          includeAutoUpgradeRole = true;
          extraSpecialArgs = { inherit unstablePkgs; };
          modules = baseModules ++ [ ./machines/cygate/configuration.nix ];
        };
        nixos-sov2 = mkHost {
          includeZfsRole = true;
          includeAutoUpgradeRole = true;
          extraSpecialArgs = { inherit unstablePkgs; };
          modules = baseModules ++ [ ./machines/cygate2/configuration.nix ];
        };
        hermes = mkHost {
          nixpkgsLib = inputs.nixpkgs-unstable.lib;
          includeAutoUpgradeRole = true;
          modules = [
            inputs.hermes-agent.nixosModules.default
            inputs.nvf.nixosModules.default
            inputs.sops_nix.nixosModules.sops
            ./machines/hermes/configuration.nix
          ];
        };
        netbird = mkHost {
          includeZfsRole = true;
          includeAutoUpgradeRole = true;
          extraSpecialArgs = { inherit unstablePkgs; };
          modules = [
            ./machines/netbird/default.nix
            inputs.nvf.nixosModules.default
            inputs.sops_nix.nixosModules.default
          ];
        };
        skullcanyon = mkHost {
          includeZfsRole = true;
          includeAutoUpgradeRole = true;
          extraSpecialArgs = { inherit unstablePkgs; };
          modules = [
            ./modules/vlan-bridges.nix
            ./modules/libvirt.nix
            ./machines/skullcanyon/default.nix
            inputs.nvf.nixosModules.default
            inputs.sops_nix.nixosModules.default
          ];
        };
        lenovo = mkHost {
          includeZfsRole = true;
          includeAutoUpgradeRole = true;
          extraSpecialArgs = { inherit unstablePkgs; };
          modules = [
            ./modules/vlan-bridges.nix
            ./modules/libvirt.nix
            ./machines/lenovo/default.nix
            inputs.nvf.nixosModules.default
            inputs.sops_nix.nixosModules.default
          ];
        };
        # nix build .#nixosConfigurations.minimalIso.config.system.build.isoImage
        minimalIso = mkHost {
          includeCommon = false;
          includeDeployUser = false;
          modules = [
            (
              { pkgs, modulesPath, ... }:
              {
                imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
                environment.systemPackages = [ pkgs.neovim ];
                programs.fish.enable = true;
              }
            )
            ./common/users.nix
          ];
        };
        graphicalIso = mkHost {
          includeCommon = false;
          includeDeployUser = false;
          modules = [
            inputs.nvf.nixosModules.default
            (
              { pkgs, modulesPath, ... }:
              {
                imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix") ];
                environment.systemPackages = [ pkgs.neovim ];
              }
            )
          ];
        };
      };
      deploy = {
        nodes = {
          vault = {
            hostname = "vault";
            groups = [ "automatic" ];
            sshUser = "deploy";
            fastConnection = false;
            autoRollback = true;
            magicRollback = true;
            profiles.system = {
              user = "root";
              path = inputs.deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.vault;
            };
          };
          services = {
            hostname = "services";
            groups = [ "automatic" ];
            sshUser = "deploy";
            fastConnection = false;
            autoRollback = true;
            magicRollback = true;
            profiles.system = {
              user = "root";
              path = inputs.deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.services;
            };
          };
          hermes = {
            hostname = "hermes";
            groups = [ "automatic" ];
            sshUser = "deploy";
            fastConnection = false;
            autoRollback = true;
            magicRollback = true;
            profiles.system = {
              user = "root";
              path = inputs.deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.hermes;
            };
          };
          netbird = {
            hostname = "netbird";
            groups = [ "automatic" ];
            sshUser = "deploy";
            fastConnection = false;
            autoRollback = true;
            magicRollback = true;
            profiles.system = {
              user = "root";
              path = inputs.deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.netbird;
            };
          };
          nixos-sov2 = {
            hostname = "nixos-sov2";
            groups = [ "automatic" ];
            sshUser = "deploy";
            fastConnection = false;
            autoRollback = true;
            magicRollback = true;
            profiles.system = {
              user = "root";
              path = inputs.deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.nixos-sov2;
            };
          };
          skullcanyon = {
            hostname = "skullcanyon";
            groups = [ "automatic" ];
            sshUser = "deploy";
            fastConnection = false;
            autoRollback = true;
            magicRollback = true;
            profiles.system = {
              user = "root";
              path = inputs.deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.skullcanyon;
            };
          };
          lenovo = {
            hostname = "lenovo";
            groups = [ "automatic" ];
            sshUser = "deploy";
            fastConnection = false;
            autoRollback = true;
            magicRollback = true;
            profiles.system = {
              user = "root";
              path = inputs.deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.lenovo;
            };
          };
          battlestation = {
            hostname = "battlestation";
            groups = [ "manual" ];
            sshUser = "deploy";
            fastConnection = false;
            autoRollback = true;
            magicRollback = true;
            profiles.system = {
              user = "root";
              path = inputs.deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.battlestation;
            };
          };
          laptop = {
            hostname = "laptop";
            groups = [ "manual" ];
            sshUser = "deploy";
            fastConnection = false;
            autoRollback = true;
            magicRollback = true;
            profiles.system = {
              user = "root";
              path = inputs.deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.laptop;
            };
          };
          bandit = {
            hostname = "bandit";
            groups = [ "infrastructure" ];
            sshUser = "deploy";
            fastConnection = false;
            autoRollback = true;
            magicRollback = true;
            profiles.system = {
              user = "root";
              path = inputs.deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.bandit;
            };
          };
        };
      };
      checks = builtins.mapAttrs (
        system: deployLib: deployLib.deployChecks self.deploy
      ) inputs.deploy-rs.lib;
      packages.${system}.deploy-rs = inputs.deploy-rs.packages.${system}.default;
    };
}
