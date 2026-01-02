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
      oidcHmacSecretFile = config.sops.secrets."nuck/authelia/oidc_hmac_secret".path;
      oidcIssuerPrivateKeyFile = config.sops.secrets."nuck/authelia/oidc_rsa_private_key".path;
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

        # The public URL where Authelia is accessible (fixes localhost:9091 redirects)
        issuer = "https://sso.${domain}";

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

        # Claims policies - include groups in ID token for role mapping
        claims_policies = {
          default = {
            id_token = ["groups" "email" "preferred_username" "name"];
          };
        };

        # OIDC clients
        clients = [
          # Forgejo OIDC client
          {
            client_id = "forgejo";
            client_name = "Forgejo";
            client_secret = "$__file{${config.sops.secrets."nuck/authelia/forgejo_oidc_client_secret".path}}";
            public = false;
            authorization_policy = "one_factor";
            claims_policy = "default";

            redirect_uris = ["https://git.${domain}/user/oauth2/authelia/callback"];

            scopes = ["openid" "profile" "groups" "email" "offline_access"];
            response_types = ["code"];
            grant_types = ["refresh_token" "authorization_code"];
            response_modes = ["form_post" "query" "fragment"];

            userinfo_signed_response_alg = "none";
          }
          # Grafana OIDC client
          {
            client_id = "grafana";
            client_name = "Grafana";
            client_secret = "$__file{${config.sops.secrets."nuck/authelia/grafana_oidc_client_secret".path}}";
            public = false;
            authorization_policy = "one_factor";
            claims_policy = "default";

            redirect_uris = ["https://grafana.${domain}/login/generic_oauth"];

            scopes = ["openid" "profile" "groups" "email"];
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
