{
  description = "Maclab infrastructure";

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

  outputs = {
    nixpkgs,
    determinate,
    ...
  } @ inputs: let
    lib = import ./lib.nix {inherit inputs;};
  in {
    # NixOS configurations
    nixosConfigurations = {
      nuck = lib.mkNixos "nuck" "x86_64-linux";
    };
  };
}
