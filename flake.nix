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
      unstablePkgs = import inputs.nixpkgs-unstable {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
      unstableSmall = import inputs.nixpkgs-unstable-small {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
    in
    {
      nixosConfigurations = {
        bandit = inputs.nixpkgs.lib.nixosSystem {
          system = system;
          specialArgs = { inherit inputs system unstablePkgs; };
          modules = [
            inputs.sops_nix.nixosModules.sops
            inputs.vpn-confinement.nixosModules.default
            inputs.nvf.nixosModules.default
            ./machines/bandit/configuration.nix
          ];
        };
        vault = inputs.nixpkgs.lib.nixosSystem {
          system = system;
          specialArgs = { inherit inputs system unstablePkgs; };
          modules = [
            inputs.nvf.nixosModules.default
            inputs.sops_nix.nixosModules.sops
            ./machines/vault/configuration.nix
          ];
        };
        laptop = inputs.nixpkgs-unstable.lib.nixosSystem {
          system = system;
          specialArgs = { inherit inputs system unstableSmall; };
          modules = [
            inputs.sops_nix.nixosModules.sops
            inputs.nvf.nixosModules.default
            ./machines/laptop/configuration.nix
            inputs.hjem.nixosModules.default
            ./hjem/default.nix
          ];
        };
        battlestation = inputs.nixpkgs-unstable.lib.nixosSystem {
          system = system;
          specialArgs = { inherit inputs system unstableSmall; };
          modules = [
            inputs.sops_nix.nixosModules.sops
            inputs.nvf.nixosModules.default
            ./machines/battlestation/configuration.nix
            inputs.hjem.nixosModules.default
            ( { pkgs, ... }: { nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ]; })
            ./hjem/default.nix
          ];
        };
        services = inputs.nixpkgs.lib.nixosSystem {
          system = system;
          specialArgs = { inherit inputs system unstablePkgs; };
          modules = [
            inputs.sops_nix.nixosModules.sops
            ./machines/services/configuration.nix
            inputs.teslamate.nixosModules.default
            inputs.authentik-nix.nixosModules.default
            inputs.nvf.nixosModules.default
          ];
        };
        nixos-sov = inputs.nixpkgs.lib.nixosSystem {
          system = system;
          specialArgs = { inherit inputs system unstablePkgs; };
          modules = [
            inputs.sops_nix.nixosModules.sops
            inputs.nvf.nixosModules.default
            ./machines/cygate/configuration.nix
          ];
        };
        nixos-sov2 = inputs.nixpkgs.lib.nixosSystem {
          system = system;
          specialArgs = { inherit inputs system unstablePkgs; };
          modules = [
            inputs.sops_nix.nixosModules.sops
            inputs.nvf.nixosModules.default
            ./machines/cygate2/configuration.nix
          ];
        };
        netbird = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs system unstablePkgs; };
          modules = [
            ./machines/netbird/default.nix
            inputs.nvf.nixosModules.default
            inputs.sops_nix.nixosModules.default
          ];
        };
        skullcanyon = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs system unstablePkgs; };
          modules = [
            ./machines/skullcanyon/default.nix
            inputs.nvf.nixosModules.default
            inputs.sops_nix.nixosModules.default
          ];
        };
        # nix build .#nixosConfigurations.minimalIso.config.system.build.isoImage
        minimalIso = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
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
        graphicalIso = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            (
              { pkgs, modulesPath, ... }:
              {
                imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix") ];
                environment.systemPackages = [ pkgs.neovim ];
              }
            )
            ./common/common.nix
          ];
        };
      };
    };
}
