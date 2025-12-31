{
  config,
  pkgs,
  ...
}: {
  # Caddy reverse proxy for HTTPS via Tailscale
  services.caddy = {
    enable = true;
    virtualHosts."nuck.finch-atria.ts.net" = {
      extraConfig = ''
        reverse_proxy localhost:9091
        tls /var/lib/tailscale/certs/nuck.finch-atria.ts.net.crt /var/lib/tailscale/certs/nuck.finch-atria.ts.net.key
      '';
    };
  };

  # Allow Caddy to access Tailscale certificates
  systemd.services.caddy.serviceConfig = {
    SupplementaryGroups = [ "tailscale" ];
  };

  # Open HTTPS port
  networking.firewall.allowedTCPPorts = [ 443 ];

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
        level = "debug";
        format = "text";
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
