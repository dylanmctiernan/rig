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
      # Media storage - NFS mount from Synology NAS
      mediaDir = "/mnt/media";
    };
  };

  # Application Services (5000-5099)
  services = {
    forgejo = {
      httpPort = 5000;
      subdomain = "git";
      stateDir = "/var/lib/forgejo";
    };
    uptimeKuma = {
      httpPort = 5001;
      subdomain = "status";
      stateDir = "/var/lib/uptime-kuma";
    };
    backrest = {
      httpPort = 5002;
      subdomain = "backup";
      stateDir = "/var/lib/backrest";
    };
    # Media Stack
    # Note: Jellyfin uses default port 8096 (NixOS service doesn't expose port option)
    jellyfin = {
      httpPort = 8096;
      subdomain = "jellyfin";
      stateDir = "/var/lib/jellyfin";
    };
    transmission = {
      httpPort = 5004;
      peerPort = 51413;
      subdomain = "transmission";
      stateDir = "/var/lib/transmission";
    };
    sonarr = {
      httpPort = 5005;
      subdomain = "sonarr";
      stateDir = "/var/lib/sonarr";
    };
    radarr = {
      httpPort = 5006;
      subdomain = "radarr";
      stateDir = "/var/lib/radarr";
    };
    lidarr = {
      httpPort = 5007;
      subdomain = "lidarr";
      stateDir = "/var/lib/lidarr";
    };
    prowlarr = {
      httpPort = 5008;
      subdomain = "prowlarr";
      stateDir = "/var/lib/prowlarr";
    };
    bazarr = {
      httpPort = 5009;
      subdomain = "bazarr";
      stateDir = "/var/lib/bazarr";
    };
  };

  # Infrastructure Services (5100-5199)
  infrastructure = {
    authelia = {
      httpPort = 5100;
      subdomain = "sso";
      stateDir = "/var/lib/authelia-main";
    };
    caddy = {
      stateDir = "/var/lib/caddy";
    };
  };

  # LGTM Stack Configuration (5200-5599)
  lgtm = {
    loki = {
      httpPort = 5200;
      grpcPort = 5300;
      stateDir = "/var/lib/loki";
    };
    grafana = {
      httpPort = 5201;
      subdomain = "grafana";
      stateDir = "/var/lib/grafana";
    };
    tempo = {
      httpPort = 5202;
      grpcPort = 5301;
      otlpGrpcPort = 5400;
      otlpHttpPort = 5401;
      stateDir = "/var/lib/tempo";
    };
    mimir = {
      httpPort = 5203;
      grpcPort = 5302;
      memberlistPort = 5500;
      stateDir = "/var/lib/mimir";
    };
    alloy = {
      httpPort = 5204;
      otlpGrpcPort = 5402;
      otlpHttpPort = 5403;
      stateDir = "/var/lib/alloy";
    };
  };
}
