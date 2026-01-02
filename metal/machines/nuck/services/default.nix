{...}: {
  imports = [
    ./coredns.nix
    ./caddy.nix
    ./authelia.nix
    ./backrest.nix
    ./forgejo.nix
    ./uptimekuma.nix
    ./uptimekuma-sync.nix
    ./lgtm
  ];
}
