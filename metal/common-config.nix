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

  # Base data directory for all persistent application data
  dataDir = "/data";

  # Application Services (5000-5099)
  services = {
    forgejo = {
      httpPort = 5000;
      subdomain = "git";
      dataDir = "/data/forgejo";
    };
    uptimeKuma = {
      httpPort = 5001;
      subdomain = "status";
      dataDir = "/data/uptime-kuma";
    };
    backrest = {
      httpPort = 5002;
      subdomain = "backup";
      dataDir = "/data/backrest";
    };
  };

  # Infrastructure Services (5100-5199)
  infrastructure = {
    authelia = {
      httpPort = 5100;
      subdomain = "sso";
      dataDir = "/data/authelia";
    };
    caddy = {
      dataDir = "/data/caddy";
    };
  };

  # LGTM Stack Configuration (5200-5599)
  lgtm = {
    loki = {
      httpPort = 5200;
      grpcPort = 5300;
      dataDir = "/data/loki";
    };
    grafana = {
      httpPort = 5201;
      subdomain = "grafana";
      dataDir = "/data/grafana";
    };
    tempo = {
      httpPort = 5202;
      grpcPort = 5301;
      otlpGrpcPort = 5400;
      otlpHttpPort = 5401;
      dataDir = "/data/tempo";
    };
    mimir = {
      httpPort = 5203;
      grpcPort = 5302;
      memberlistPort = 5500;
      dataDir = "/data/mimir";
    };
    alloy = {
      httpPort = 5204;
      otlpGrpcPort = 5402;
      otlpHttpPort = 5403;
      # No dataDir - ephemeral data only
    };
  };
}
