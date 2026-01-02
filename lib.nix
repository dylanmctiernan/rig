{inputs}: {
  # Common configuration nixos system builder
  mkNixos = machine:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};

      modules = [
        # Load determinate module for determinate nix.
        # We assume all nixos hosts are determinate nix hosts, so we don't need to enable flakes for example.
        inputs.determinate.nixosModules.default

        # Sops-nix for secrets management
        inputs.sops-nix.nixosModules.sops

        # Nixarr module for media server stack
        inputs.nixarr.nixosModules.default

        # Use the specific machine configuration
        ./metal/machines/${machine}
      ];
    };

  # Darwin (macOS) system builder
  mkDarwin = machine:
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = {inherit inputs;};

      modules = [
        # Home manager for user configuration
        inputs.home-manager.darwinModules.home-manager

        # Use the specific machine configuration
        ./metal/machines/${machine}
      ];
    };
}
