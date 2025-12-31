{
  config,
  pkgs,
  ...
}: {
  # Caddy web server with subdomain routing
  services.caddy = {
    enable = true;

    # Global Caddy configuration
    globalConfig = ''
      # Disable automatic HTTPS redirects for Tailscale
      auto_https disable_redirects

      # Enable admin API for runtime config
      admin localhost:2019
    '';

    # Virtual hosts - subdomain-based routing
    virtualHosts = {
      # Authelia subdomain
      "auth.nuck.finch-atria.ts.net" = {
        extraConfig = ''
          # Use Tailscale HTTPS certificates
          tls /var/lib/tailscale/certs/nuck.finch-atria.ts.net.crt /var/lib/tailscale/certs/nuck.finch-atria.ts.net.key {
            protocols tls1.2 tls1.3
          }

          reverse_proxy localhost:9091
        '';
      };

      # Root domain - landing page or dashboard
      "nuck.finch-atria.ts.net" = {
        extraConfig = ''
          tls /var/lib/tailscale/certs/nuck.finch-atria.ts.net.crt /var/lib/tailscale/certs/nuck.finch-atria.ts.net.key

          respond "nuck.finch-atria.ts.net - Services available" 200
        '';
      };
    };
  };

  # Grant Caddy access to Tailscale certificates
  systemd.services.caddy.serviceConfig = {
    # Allow reading Tailscale certs
    ReadOnlyPaths = [ "/var/lib/tailscale/certs" ];
    # Run as caddy user with supplementary groups
    SupplementaryGroups = [ ];
  };

  # Open ports
  networking.firewall.allowedTCPPorts = [ 80 443 9091 ];

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

      # Session configuration - Use tailscale domain
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
