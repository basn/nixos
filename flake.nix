{
  description = "Basn flake for machines.";
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs?ref=nixos-25.11-small";
    };
    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs?ref=nixos-unstable";
    };
    nixpkgs-unstable-small = {
      url = "github:nixos/nixpkgs?ref=nixos-unstable-small";
    };
    sops_nix = {
      url = "github:Mic92/sops-nix";
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
    teslamate = {
      url = "github:teslamate-org/teslamate/main";
    };
    authentik-nix = {
      url = "github:nix-community/authentik-nix";
    };
    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel";
    };
  };
  outputs =
    inputs:
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
          useManCacheEnable ? false,
          extraSpecialArgs ? { },
        }:
        nixpkgsLib.nixosSystem {
          inherit system;
          modules = lib.optionals includeCommon [ ./common/common.nix ] ++ modules;
          specialArgs =
            {
              inherit
                inputs
                system
                useManCacheEnable
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
          extraSpecialArgs = { inherit unstablePkgs; };
          modules = baseModules ++ [
            inputs.vpn-confinement.nixosModules.default
            ./machines/bandit/configuration.nix
          ];
        };
        vault = mkHost {
          extraSpecialArgs = { inherit unstablePkgs; };
          modules = baseModules ++ [ ./machines/vault/configuration.nix ];
        };
        laptop = mkHost {
          nixpkgsLib = inputs.nixpkgs-unstable.lib;
          useManCacheEnable = true;
          extraSpecialArgs = { inherit unstableSmall; };
          modules = baseModules ++ [
            ./machines/laptop/configuration.nix
            inputs.hjem.nixosModules.default
            ./hjem/default.nix
          ];
        };
        battlestation = mkHost {
          nixpkgsLib = inputs.nixpkgs-unstable.lib;
          useManCacheEnable = true;
          extraSpecialArgs = { inherit unstableSmall; };
          modules = baseModules ++ [
            ./machines/battlestation/configuration.nix
            inputs.hjem.nixosModules.default
            ({ ... }: { nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ]; })
            ./hjem/default.nix
          ];
        };
        services = mkHost {
          extraSpecialArgs = { inherit unstablePkgs; };
          modules = [
            inputs.sops_nix.nixosModules.sops
            ./machines/services/configuration.nix
            inputs.teslamate.nixosModules.default
            inputs.authentik-nix.nixosModules.default
            inputs.nvf.nixosModules.default
          ];
        };
        nixos-sov = mkHost {
          extraSpecialArgs = { inherit unstablePkgs; };
          modules = baseModules ++ [ ./machines/cygate/configuration.nix ];
        };
        nixos-sov2 = mkHost {
          extraSpecialArgs = { inherit unstablePkgs; };
          modules = baseModules ++ [ ./machines/cygate2/configuration.nix ];
        };
        netbird = mkHost {
          extraSpecialArgs = { inherit unstablePkgs; };
          modules = [
            ./machines/netbird/default.nix
            inputs.nvf.nixosModules.default
            inputs.sops_nix.nixosModules.default
          ];
        };
        skullcanyon = mkHost {
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
          extraSpecialArgs = { inherit unstablePkgs; };
          modules = [
            ./machines/lenovo/default.nix
            inputs.nvf.nixosModules.default
            inputs.sops_nix.nixosModules.default
          ];
        };
        # nix build .#nixosConfigurations.minimalIso.config.system.build.isoImage
        minimalIso = mkHost {
          includeCommon = false;
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
    };
}
