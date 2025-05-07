{
  description = "Basn flake for machines.";
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs?ref=nixos-24.11";
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
      inputs = {
        nixpkgs = {
	  follows = "nixpkgs";
	};
      };
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
        ];
      };
    };
    homeConfigurations = {
      "basn" = inputs.home-manager.lib.homeManagerConfiguration {
       pkgs = pkgs;
       modules = [ ./home/home.nix ]; 
     };
    };
  };
}
