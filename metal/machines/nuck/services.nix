{
  config,
  pkgs,
  ...
}: {
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
        format = "text";
      };

      # Server configuration - Listen on all interfaces for tailnet access
      server = {
        address = "tcp://0.0.0.0:9091";
        endpoints.authz.forward-auth.implementation = "ForwardAuth";
      };

      # Session configuration - Use tailnet IP
      # Access Authelia at http://100.114.41.97:9091 (use IP, not hostname)
      # For production: set up reverse proxy with HTTPS and proper domain
      session = {
        domain = "100.114.41.97";
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
            domain = "nuck.local";
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

  # Open firewall for Authelia on tailnet
  networking.firewall.allowedTCPPorts = [ 9091 ];
}
