{
  description = "Basn flake for machines.";
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs?ref=nixos-25.05";
    };
    nixpkgs-unstable = {
      url = "github:nixos/nixpkgs?ref=nixos-unstable";
    };
    sops_nix = {
      url = "github:Mic92/sops-nix";
    };
    vpn-confinement = {
      url = "github:Maroka-chan/VPN-Confinement";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nvf = {
      url = "github:notashelf/nvf";
    };
    nix-search-tv = {
      url = "github:3timeslazy/nix-search-tv";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
    };
    teslamate = {
      url = "github:teslamate-org/teslamate/main";
    };
    authentik-nix = {
      url = "github:nix-community/authentik-nix";
    };
  };
  outputs = inputs:
  let
    system = "x86_64-linux";
    unstablePkgs = import inputs.nixpkgs-unstable {
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
        specialArgs = {
          inherit inputs system unstablePkgs;
        };
        modules = [
          inputs.sops_nix.nixosModules.sops
          inputs.vpn-confinement.nixosModules.default
          ./machines/bandit/configuration.nix
          inputs.home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = false;
              useUserPackages = true;
              users.basn = import ./home/home.nix;
              backupFileExtension = "backup";
              extraSpecialArgs = {
                pkgs = unstablePkgs;
              };
              sharedModules = [
                inputs.nvf.homeManagerModules.default
              ];
            };
          }
        ];
      };
      laptop = inputs.nixpkgs-unstable.lib.nixosSystem {
        system = system;
        specialArgs = {
          inherit inputs system;
        };
        modules = [
          inputs.sops_nix.nixosModules.sops
          ./machines/laptop/configuration.nix
          inputs.home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = false;
              useUserPackages = true;
              users.basn = import ./home/home.nix;
              backupFileExtension = "backup";
              extraSpecialArgs = {
                pkgs = unstablePkgs;
              };
              sharedModules = [
                inputs.nvf.homeManagerModules.default
              ];
            };
          }
        ];
      };
      services = inputs.nixpkgs.lib.nixosSystem {
        system = system;
        specialArgs = {
          inherit inputs system unstablePkgs;
        };
        modules = [
          inputs.sops_nix.nixosModules.sops
          ./machines/services/configuration.nix
          inputs.teslamate.nixosModules.default
          inputs.authentik-nix.nixosModules.default
          inputs.home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = false;
              useUserPackages = true;
              users.basn = import ./home/home.nix;
              backupFileExtension = "backup";
              extraSpecialArgs = {
                pkgs = unstablePkgs;
              };
              sharedModules = [
                inputs.nvf.homeManagerModules.default
              ];
            };
          }
        ];
      };
      nixos-sov = inputs.nixpkgs.lib.nixosSystem {
        system = system;
        specialArgs = {
          inherit inputs system unstablePkgs;
        };
        modules = [
          inputs.sops_nix.nixosModules.sops
          ./machines/cygate/configuration.nix
          inputs.home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = false;
              useUserPackages = true;
              users.basn = import ./home/home.nix;
              backupFileExtension = "backup";
              extraSpecialArgs = {
                pkgs = unstablePkgs;
              };
              sharedModules = [
                inputs.nvf.homeManagerModules.default
              ];
            };
          }
	];
      };
      nixos-sov2 = inputs.nixpkgs.lib.nixosSystem {
        system = system;
        specialArgs = {
          inherit inputs system unstablePkgs;
        };
        modules = [
          inputs.sops_nix.nixosModules.sops
          ./machines/cygate2/configuration.nix
          inputs.home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = false;
              useUserPackages = true;
              users.basn = import ./home/home.nix;
              backupFileExtension = "backup";
              extraSpecialArgs = {
                pkgs = unstablePkgs;
              };
              sharedModules = [
                inputs.nvf.homeManagerModules.default
              ];
            };
          }
        ];
      };
      nixos = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          inputs.nixos-wsl.nixosModules.default
          {
            system.stateVersion = "24.11";
            wsl.enable = true;
          }
	  ./machines/wsl/configuration.nix
          inputs.home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = false;
              useUserPackages = true;
              users.basn = import ./home/home.nix;
              backupFileExtension = "backup";
              extraSpecialArgs = {
                pkgs = unstablePkgs;
              };
              sharedModules = [
                inputs.nvf.homeManagerModules.default
              ];
            };
	  }
        ];
     };
     # nix build .#nixosConfigurations.minimalIso.config.system.build.isoImage
     minimalIso = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ pkgs, modulesPath, ... }: {
            imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
            environment.systemPackages = [ pkgs.neovim ];
          })
          ./common/users.nix
        ];
      };
     graphicalIso = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ pkgs, modulesPath, ... }: {
            imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix") ];
            environment.systemPackages = [ pkgs.neovim ];
          })
          ./common/common.nix
        ];
      };
    };
  };
}
