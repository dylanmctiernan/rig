{inputs}: {
  # Common configuration nixos system builder
  mkNixos = machine: systemArch:
    inputs.nixpkgs.lib.nixosSystem {
      system = systemArch;

      specialArgs = {inherit inputs;};

      modules = [
        # Load determinate module for determinate nix.
        # We assume all nixos hosts are determinate nix hosts, so we don't need to enable flakes for example.
        inputs.determinate.nixosModules.default

        # Sops-nix for secrets management
        inputs.sops-nix.nixosModules.sops

        # Use the specific machine configuration
        ./metal/machines/${machine}
      ];
    };
}
