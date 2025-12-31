{config, ...}: {
  # Authelia - Authentication and authorization server
  services.authelia.instances.main = {
    enable = true;

    secrets = {
      jwtSecretFile = config.sops.secrets."authelia/jwt_secret".path;
      storageEncryptionKeyFile = config.sops.secrets."authelia/storage_encryption_key".path;
      sessionSecretFile = config.sops.secrets."authelia/session_secret".path;
    };

    settings = {
      theme = "auto";
      default_2fa_method = "totp";

      log = {
        level = "info";
        format = "json";
      };

      # Listen on localhost - behind Caddy
      server = {
        address = "tcp://127.0.0.1:9091";
        endpoints.authz.forward-auth.implementation = "ForwardAuth";
      };

      # Session for mac.lab domain
      session = {
        domain = "mac.lab";
        same_site = "lax";
        expiration = "1h";
        inactivity = "5m";
      };

      storage.local.path = "/var/lib/authelia-main/db.sqlite3";

      # Access control for mac.lab
      access_control = {
        default_policy = "one_factor";
        rules = [
          {
            domain = "mac.lab";
            policy = "one_factor";
          }
          {
            domain = "*.mac.lab";
            policy = "one_factor";
          }
        ];
      };

      notifier.filesystem = {
        filename = "/var/lib/authelia-main/notifications.txt";
      };

      authentication_backend.file = {
        path = "/var/lib/authelia-main/users.yml";
      };
    };
  };
}
