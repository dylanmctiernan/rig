{...}: {
  imports = [
    ./coredns.nix
    ./caddy.nix
    ./authelia.nix
  ];
}
