{config, ...}: let
  commonConfig = import ../../../common-config.nix;
  domain = commonConfig.network.domain;
in {
  # Authelia - Authentication and authorization server
  services.authelia.instances.main = {
    enable = true;

    secrets = {
      jwtSecretFile = config.sops.secrets."nuck/authelia/jwt_secret".path;
      storageEncryptionKeyFile = config.sops.secrets."nuck/authelia/storage_encryption_key".path;
      sessionSecretFile = config.sops.secrets."nuck/authelia/session_secret".path;
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

      # Session for ${domain} domain
      session = {
        domain = domain;
        same_site = "lax";
        expiration = "1h";
        inactivity = "5m";
      };

      storage.local.path = "/var/lib/authelia-main/db.sqlite3";

      # Access control for ${domain}
      access_control = {
        default_policy = "one_factor";
        rules = [
          {
            domain = domain;
            policy = "one_factor";
          }
          {
            domain = "*.${domain}";
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
