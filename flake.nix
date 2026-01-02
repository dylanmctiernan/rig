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
    colmena,
    ...
  } @ inputs: let
    lib = import ./lib.nix {inherit inputs;};
  in {
    # NixOS configurations
    nixosConfigurations = {
      nuck = lib.mkNixos "nuck";
    };

    # Darwin (macOS) configurations
    darwinConfigurations = {
      dylbook = lib.mkDarwin "dylbook";
    };

    # Colmena deployment configuration
    colmena = let
      hive = {
        meta = {
          nixpkgs = import nixpkgs {system = "x86_64-linux";};
          specialArgs = {inherit inputs;};
        };

        # NixOS host (nuck)
        nuck = {name, nodes, ...}: {
          deployment = {
            targetHost = "nuck";
            buildOnTarget = true;
            # SSH over Tailscale, no keys needed
          };
          imports = [
            inputs.determinate.nixosModules.default
            inputs.sops-nix.nixosModules.sops
            ./metal/machines/nuck
          ];
        };
      };
    in
      hive // {
        processFlake = inputs.colmena.lib.makeHive hive;
      };

    # Development shell
    devShells = {
      aarch64-darwin.default = let
        pkgs = import nixpkgs {system = "aarch64-darwin";};
      in
        pkgs.mkShell {
          packages = [
            pkgs.just
            pkgs.colmena
            pkgs.age
            pkgs.sops
          ];
        };

      x86_64-linux.default = let
        pkgs = import nixpkgs {system = "x86_64-linux";};
      in
        pkgs.mkShell {
          packages = [
            pkgs.just
            pkgs.colmena
            pkgs.age
            pkgs.sops
          ];
        };
    };
  };
}
