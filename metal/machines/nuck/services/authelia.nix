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
      oidcHmacSecretFile = config.sops.secrets."nuck/authelia/oidc_hmac_secret".path;
      oidcIssuerPrivateKeyFile = null;  # Using HMAC instead of RSA
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
        cookies = [
          {
            domain = domain;
            authelia_url = "https://sso.${domain}";
            same_site = "lax";
            expiration = "1h";
            inactivity = "5m";
          }
        ];
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

      # OpenID Connect (OIDC) configuration
      identity_providers.oidc = {
        enable_client_debug_messages = false;
        enforce_pkce = "public_clients_only";

        # JWKS configuration - using HMAC for token signing
        # The key is loaded from oidcHmacSecretFile
        jwks = [
          {
            key_id = "main";
            algorithm = "HS512";
            use = "sig";
            key = "{{ secret \"/var/lib/authelia-main/secrets/oidc-hmac\" }}";
          }
        ];

        lifespans = {
          access_token = "1h";
          authorize_code = "1m";
          id_token = "1h";
          refresh_token = "90m";
        };

        cors = {
          endpoints = ["authorization" "token" "revocation" "introspection"];
          allowed_origins_from_client_redirect_uris = true;
        };

        # Forgejo OIDC client
        clients = [
          {
            client_id = "forgejo";
            client_name = "Forgejo";
            # Using $plaintext$ prefix - Authelia will hash it on startup
            # Secret stored in sops: nuck/authelia/forgejo_client_secret
            client_secret = "$plaintext$b87067421779d30d7ba8a78a4028fe3c0105eb433f16612bb37fc39866f4b43b";
            public = false;
            authorization_policy = "one_factor";

            redirect_uris = ["https://git.${domain}/user/oauth2/authelia/callback"];

            scopes = ["openid" "profile" "groups" "email" "offline_access"];
            response_types = ["code"];
            grant_types = ["refresh_token" "authorization_code"];
            response_modes = ["form_post" "query" "fragment"];

            userinfo_signed_response_alg = "none";
          }
        ];
      };
    };
  };
}
