{
  config,
  pkgs,
  ...
}: {
  # Caddy reverse proxy for HTTPS
  # Best practices: Use email for ACME, enable automatic HTTPS
  services.caddy = {
    enable = true;
    email = "dylan@finch-atria.ts.net"; # For Let's Encrypt/ACME notifications

    # Global options
    globalConfig = ''
      auto_https disable_redirects
    '';

    virtualHosts."nuck.finch-atria.ts.net" = {
      extraConfig = ''
        # Use Tailscale certificates (copied to Caddy's directory)
        tls /var/lib/caddy/certificates/nuck.finch-atria.ts.net.crt /var/lib/caddy/certificates/nuck.finch-atria.ts.net.key

        # Reverse proxy to Authelia
        reverse_proxy localhost:9091 {
          # Pass real IP to backend
          header_up X-Real-IP {remote_host}
          header_up X-Forwarded-For {remote_host}
          header_up X-Forwarded-Proto {scheme}
          header_up X-Forwarded-Host {host}
        }

        # Security headers
        header {
          # Enable HSTS
          Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
          # Prevent clickjacking
          X-Frame-Options "DENY"
          # Prevent MIME sniffing
          X-Content-Type-Options "nosniff"
          # Remove server header
          -Server
        }

        # Logging
        log {
          output file /var/log/caddy/nuck.finch-atria.ts.net.log
          format json
        }
      '';
    };
  };

  # Ensure log and certificate directories exist
  systemd.tmpfiles.rules = [
    "d /var/log/caddy 0750 caddy caddy -"
    "d /var/lib/caddy/certificates 0750 caddy caddy -"
  ];

  # Copy Tailscale certificates for Caddy
  systemd.services.copy-tailscale-certs = {
    description = "Copy Tailscale certificates for Caddy";
    wantedBy = [ "caddy.service" ];
    before = [ "caddy.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '\
        cp /var/lib/tailscale/certs/nuck.finch-atria.ts.net.crt /var/lib/caddy/certificates/ && \
        cp /var/lib/tailscale/certs/nuck.finch-atria.ts.net.key /var/lib/caddy/certificates/ && \
        chown caddy:caddy /var/lib/caddy/certificates/* && \
        chmod 644 /var/lib/caddy/certificates/*.crt && \
        chmod 600 /var/lib/caddy/certificates/*.key'";
    };
  };

  # Periodically sync certificates (Tailscale certs renew automatically)
  systemd.timers.copy-tailscale-certs = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "1d";
    };
  };

  # Open HTTPS port (HTTP port 80 for ACME challenges if needed)
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # Authelia - Authentication and authorization server
  services.authelia.instances.main = {
    enable = true;

    # Secrets management - IMPORTANT: Keep these out of the nix store
    # Create these files manually or use sops-nix
    secrets = {
      jwtSecretFile = "/var/lib/authelia-main/secrets/jwt";
      storageEncryptionKeyFile = "/var/lib/authelia-main/secrets/storage-encryption-key";
      sessionSecretFile = "/var/lib/authelia-main/secrets/session";
    };

    settings = {
      # Theme configuration
      theme = "auto";
      default_2fa_method = "totp";

      # Logging
      log = {
        level = "info";
        format = "json";
      };

      # Server configuration - Listen on localhost only (behind Caddy)
      server = {
        address = "tcp://127.0.0.1:9091";
        endpoints.authz.forward-auth.implementation = "ForwardAuth";
      };

      # Session configuration - Use HTTPS via Caddy
      # Access via https://nuck.finch-atria.ts.net
      session = {
        domain = "finch-atria.ts.net";
        same_site = "lax";
        expiration = "1h";
        inactivity = "5m";
      };

      # Storage configuration (local SQLite for simplicity)
      storage.local.path = "/var/lib/authelia-main/db.sqlite3";

      # Access control - Allow access from tailnet
      access_control = {
        default_policy = "one_factor";
        rules = [
          {
            domain = "finch-atria.ts.net";
            policy = "one_factor";
          }
        ];
      };

      # Notifier configuration - File-based for now
      # TODO: Configure SMTP for production use
      notifier.filesystem = {
        filename = "/var/lib/authelia-main/notifications.txt";
      };

      # Authentication backend - File-based for simplicity
      # TODO: Consider LDAP/AD integration for production
      authentication_backend.file = {
        path = "/var/lib/authelia-main/users.yml";
      };
    };
  };

}
