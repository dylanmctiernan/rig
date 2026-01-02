{...}: {
  imports = [
    ./coredns.nix
    ./caddy.nix
    ./authelia.nix
    ./backrest.nix
    ./forgejo.nix
    ./uptimekuma.nix
    ./lgtm
    ./nfs-media.nix
    ./media.nix
  ];
}
