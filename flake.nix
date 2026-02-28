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

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs = {
      url = "github:szlend/deploy-rs/fix-show-derivation-parsing";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      determinate,
      sops-nix,
      nix-darwin,
      home-manager,
      deploy-rs,
      ...
    }@inputs:
    let
      vars = import ./vars;
    in
    {
      nixosConfigurations.nuck = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };

        modules = [
          determinate.nixosModules.default
          sops-nix.nixosModules.sops
          ./metal/machines/nuck
        ];
      };

      darwinConfigurations.dylbook = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };

        modules = [
          home-manager.darwinModules.home-manager
          ./metal/machines/dylbook
        ];
      };

      deploy = {
        nodes.nuck = {
          hostname = vars.machines.nuck.lanIp;
          sshUser = vars.people.dylan.host.username;
          remoteBuild = true;
          profiles.system = {
            user = "root";
            sudo = "sudo -u";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nuck;
          };
        };
      };

      # checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

      apps = {
        aarch64-darwin.deploy-rs = {
          type = "app";
          program = "${deploy-rs.packages.aarch64-darwin.default}/bin/deploy";
        };
        x86_64-linux.deploy-rs = {
          type = "app";
          program = "${deploy-rs.packages.x86_64-linux.default}/bin/deploy";
        };
      };
    };
}
