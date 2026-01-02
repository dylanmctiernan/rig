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

  # Uptime Kuma Monitor Configuration
  # This uses a function to generate monitor configs dynamically from service definitions
  monitoring = rec {
    # Helper to build internal localhost URL
    mkInternalUrl = port: path: "http://127.0.0.1:${toString port}${path}";

    # Helper to build external HTTPS URL
    mkExternalUrl = subdomain: domain: "https://${subdomain}.${domain}";

    groups = {
      # Internal Services - Direct localhost monitoring
      internal = {
        name = "Internal Services (localhost)";
        monitors = [
          {
            name = "Forgejo";
            type = "http";
            url = mkInternalUrl services.forgejo.httpPort "";
            interval = 60;
          }
          {
            name = "Authelia";
            type = "http";
            url = mkInternalUrl infrastructure.authelia.httpPort "/api/health";
            interval = 60;
          }
          {
            name = "Backrest";
            type = "http";
            url = mkInternalUrl services.backrest.httpPort "";
            interval = 60;
          }
          {
            name = "Loki";
            type = "http";
            url = mkInternalUrl lgtm.loki.httpPort "/ready";
            interval = 60;
          }
          {
            name = "Grafana";
            type = "http";
            url = mkInternalUrl lgtm.grafana.httpPort "/api/health";
            interval = 60;
          }
          {
            name = "Tempo";
            type = "http";
            url = mkInternalUrl lgtm.tempo.httpPort "/ready";
            interval = 60;
          }
          {
            name = "Mimir";
            type = "http";
            url = mkInternalUrl lgtm.mimir.httpPort "/ready";
            interval = 60;
          }
          {
            name = "Alloy";
            type = "http";
            url = mkInternalUrl lgtm.alloy.httpPort "/-/ready";
            interval = 60;
          }
        ];
      };

      # External Services - Through Caddy with TLS
      external = {
        name = "External Services (*.mac.lab)";
        monitors = [
          {
            name = "SSO (${infrastructure.authelia.subdomain}.${network.domain})";
            type = "http";
            url = mkExternalUrl infrastructure.authelia.subdomain network.domain;
            interval = 60;
            ignoreTls = true;  # Internal CA
          }
          {
            name = "Git (${services.forgejo.subdomain}.${network.domain})";
            type = "http";
            url = mkExternalUrl services.forgejo.subdomain network.domain;
            interval = 60;
            ignoreTls = true;
          }
          {
            name = "Backup (${services.backrest.subdomain}.${network.domain})";
            type = "http";
            url = mkExternalUrl services.backrest.subdomain network.domain;
            interval = 60;
            ignoreTls = true;
          }
          {
            name = "Grafana (${lgtm.grafana.subdomain}.${network.domain})";
            type = "http";
            url = mkExternalUrl lgtm.grafana.subdomain network.domain;
            interval = 60;
            ignoreTls = true;
          }
          {
            name = "Status (${services.uptimeKuma.subdomain}.${network.domain})";
            type = "http";
            url = mkExternalUrl services.uptimeKuma.subdomain network.domain;
            interval = 60;
            ignoreTls = true;
          }
        ];
      };
    };
  };
}
