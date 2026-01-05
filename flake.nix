{
  description = "Homelab infrastructure";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    {
      self,
      nixpkgs,
      determinate,
      sops-nix,
      ...
    }@inputs:
    {
      nixosConfigurations.nuck = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };

        modules = [
          determinate.nixosModules.default
          sops-nix.nixosModules.sops
          ./metal/machines/nuck
        ];
      };

    };
}
