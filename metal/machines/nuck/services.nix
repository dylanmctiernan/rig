{
  config,
  pkgs,
  ...
}: {
  # Open port 9091 for Authelia
  networking.firewall.allowedTCPPorts = [ 9091 ];

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

      # Server configuration - Listen on all interfaces
      server = {
        address = "tcp://0.0.0.0:9091";
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
