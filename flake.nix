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
    pkgs = import inputs.nixpkgs {
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
          ./bandit/configuration.nix
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
          ./services/configuration.nix
          inputs.teslamate.nixosModules.default
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
          ./cygate/configuration.nix
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
	  ./wsl/configuration.nix
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
     exampleIso = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ pkgs, modulesPath, ... }: {
            imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
            environment.systemPackages = [ pkgs.neovim ];
          })
        ];
      };
    };
  };
}
