{
  description = "Basn flake for machines.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    sops_nix.url = "github:Mic92/sops-nix";
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
    home-manager.url = "github:nix-community/home-manager";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, flake-parts, nixpkgs, nixpkgs-unstable, home-manager, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = [ "x86_64-linux" ];

      # No perSystem for now

      flake = let
        system = "x86_64-linux";

        unstableOverlay = final: prev: {
          unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
        };

        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        nixosConfigurations.bandit = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs system;
            unstablePkgs = import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
            };
          };
          modules = [
            ({ pkgs, ... }: {
              nixpkgs.overlays = [ unstableOverlay ];
            })

            inputs.sops_nix.nixosModules.sops
            inputs.vpn-confinement.nixosModules.default
            inputs.home-manager.nixosModules.home-manager
            ./bandit/configuration.nix
          ];
        };

        homeConfigurations.bandit = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home/home.nix
          ];
          extraSpecialArgs = {
            inherit inputs system;
          };
        };
      };
    };
}

