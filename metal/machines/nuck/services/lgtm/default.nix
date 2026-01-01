{...}: {
  imports = [
    ./loki.nix
    ./grafana.nix
    ./tempo.nix
    ./mimir.nix
    ./alloy.nix
  ];
}
