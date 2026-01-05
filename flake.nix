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

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      determinate,
      sops-nix,
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

      deploy = {
        nodes.nuck = {
          hostname = vars.machines.nuck.lanIp;
          sshUser = "dylan";
          remoteBuild = true;
          profiles.system = {
            user = "root";
            sudo = "sudo -u";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nuck;
          };
        };
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
