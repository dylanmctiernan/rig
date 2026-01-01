# Shared configuration values for mac.lab infrastructure
# Non-sensitive values that are used across multiple machines
{
  # Dylan's personal information
  dylan = {
    name = "Dylan McTiernan";
    email = "dylan@mctiernan.io";
    sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE9aV63mII6UUHP9Shz6zMmGIlAd752I7LzgMTEshkYN dylan@mctiernan.io";
  };

  # Network configuration
  network = {
    domain = "mac.lab";
  };

  # Machine-specific configuration
  machines = {
    nuck = {
      tailscaleIp = "100.114.41.97";
      hostname = "nuck";
    };
  };

  # LGTM Stack Configuration (Loki, Grafana, Tempo, Mimir)
  lgtm = {
    loki = {
      httpPort = 3100;
      grpcPort = 9096;
    };
    grafana = {
      httpPort = 3200;
    };
    tempo = {
      httpPort = 3300;
      grpcPort = 9097;
      otlpHttpPort = 4318;
      otlpGrpcPort = 4317;
    };
    mimir = {
      httpPort = 9009;
      grpcPort = 9095;
    };
    alloy = {
      httpPort = 12345;
    };
  };
}
