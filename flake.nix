{
  description = "Basn flake for machines.";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    sops_nix.url = "github:Mic92/sops-nix";
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
  };
  outputs = { self, nixpkgs, nixpkgs-unstable, sops_nix, vpn-confinement, }:
  let
    system = "x86_64-linux";
    unstablePkgs = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in
  {
    nixosConfigurations = {
      bandit = nixpkgs.lib.nixosSystem {
        system = system;
        specialArgs = {
          inherit system unstablePkgs;
          inherit sops_nix;
        };
        modules = [
	  sops_nix.nixosModules.sops
	  vpn-confinement.nixosModules.default
          ./bandit/configuration.nix
        ];
      };
    };
  };
}
