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

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    determinate,
    nix-darwin,
    home-manager,
    ...
  } @ inputs: let
    lib = import ./lib.nix {inherit inputs;};
  in {
    # NixOS configurations
    nixosConfigurations = {
      nuck = lib.mkNixos "nuck" "x86_64-linux";
    };

    # Darwin (macOS) configurations
    darwinConfigurations = {
      dylbook = lib.mkDarwin "dylbook" "aarch64-darwin";
    };

    # Colmena deployment configuration
    colmena = {
      meta = {
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
        };
      };

      # NixOS host (nuck)
      nuck = {name, nodes, ...}: {
        deployment = {
          targetHost = "nuck";
          targetUser = "dylan";
          # SSH over Tailscale, no keys needed
        };
        imports = self.nixosConfigurations.nuck.config.system.build.toplevel;
      };
    };
  };
}
