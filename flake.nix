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
    home-manager-unstable = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    home-manager = {
      url = "github:nix-community/home-manager?ref=release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvf = {
      url = "github:notashelf/nvf/v0.8";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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
    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
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
      	  inputs.nvf.nixosModules.default
          ./machines/bandit/configuration.nix
          inputs.home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = false;
              useUserPackages = true;
              users.basn = import ./home/server.nix;
              backupFileExtension = "backup";
            };
          }
        ];
      };
      vault = inputs.nixpkgs.lib.nixosSystem {
        system = system;
        specialArgs = {
          inherit inputs system unstablePkgs;
        };
        modules = [
	        inputs.nvf.nixosModules.default
          ./machines/vault/configuration.nix
          inputs.home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = false;
              useUserPackages = true;
              users.basn = import ./home/server.nix;
              backupFileExtension = "backup";
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
          inputs.nvf.nixosModules.default
          ./machines/laptop/configuration.nix
          inputs.home-manager-unstable.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = false;
              useUserPackages = true;
              users.basn = import ./home/home.nix;
              backupFileExtension = "backup";
            };
          }
        ];
      };
      battlestation = inputs.nixpkgs-unstable.lib.nixosSystem {
        system = system;
        specialArgs = {
          inherit inputs system;
        };
        modules = [
          inputs.sops_nix.nixosModules.sops
       	  inputs.nvf.nixosModules.default
          inputs.chaotic.nixosModules.default
          ./machines/battlestation/configuration.nix
          inputs.home-manager-unstable.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = false;
              useUserPackages = true;
              users.basn = import ./home/gui.nix;
              backupFileExtension = "backup";
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
       	  inputs.nvf.nixosModules.default
          inputs.home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = false;
              useUserPackages = true;
              users.basn = import ./home/server.nix;
              backupFileExtension = "backup";
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
      	  inputs.nvf.nixosModules.default
          ./machines/cygate/configuration.nix
          inputs.home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = false;
              useUserPackages = true;
              users.basn = import ./home/server.nix;
              backupFileExtension = "backup";
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
	        inputs.nvf.nixosModules.default
          ./machines/cygate2/configuration.nix
          inputs.home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = false;
              useUserPackages = true;
              users.basn = import ./home/server.nix;
              backupFileExtension = "backup";
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
	        inputs.nvf.nixosModules.default
          inputs.home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = false;
              useUserPackages = true;
              users.basn = import ./home/server.nix;
              backupFileExtension = "backup";
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
