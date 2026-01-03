{config, pkgs, ...}: let
  commonConfig = import ../../../common-config.nix;
  domain = commonConfig.network.domain;
  authelia = commonConfig.infrastructure.authelia;

  # Declarative users.yml file
  usersYml = pkgs.writeText "authelia-users.yml" ''
    users:
      dylan:
        displayname: "Dylan McTiernan"
        email: dylan@mctiernan.io
        password: "$pbkdf2-sha512$310000$j908kQHxWpYtDlVMy/hdlQ$nqYc/mw0gDvcCd7/0ZG8h2jXm/XWYx4oPs.99DbHjbPFoV.SZpX8DC1Xx5gZRM7Dk6vXO0m72ztCbuRF//mjog"
        groups:
          - admins
  '';
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
        address = "tcp://127.0.0.1:${toString authelia.httpPort}";
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

      storage.local.path = "${authelia.stateDir}/db.sqlite3";

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
        filename = "${authelia.stateDir}/notifications.txt";
      };

      authentication_backend.file = {
        path = "${authelia.stateDir}/users.yml";
      };

      # OpenID Connect (OIDC) configuration
      identity_providers.oidc = {
        enable_client_debug_messages = true;
        enforce_pkce = "public_clients_only";

        # Enable Pushed Authorization Requests (PAR) - don't require it for all clients
        require_pushed_authorization_requests = false;

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
            # Use bcrypt hashed secret for client_secret_post authentication
            client_secret = "$2b$05$VgS2Sk6rCYGMXnuAc1YvPeDNwzW7/7sYNZsQrJzGhZVIeUbH0MtI2";
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
            # Use bcrypt hashed secret for client_secret_basic authentication
            client_secret = "$2b$05$aFXPGfza2jBL8lSjcySzuu6LvwXmKuVgDmmu8PV2jkeISS2KkMrEC";
            public = false;
            authorization_policy = "one_factor";
            claims_policy = "default";

            # Match Grafana's default authentication method
            token_endpoint_auth_method = "client_secret_basic";

            redirect_uris = ["https://grafana.${domain}/login/generic_oauth"];

            scopes = ["openid" "profile" "groups" "email" "offline_access"];
            response_types = ["code"];
            grant_types = ["refresh_token" "authorization_code"];
            response_modes = ["form_post" "query" "fragment"];

            userinfo_signed_response_alg = "none";
          }
          # Jellyfin OIDC client
          {
            client_id = "jellyfin";
            client_name = "Jellyfin";
            # Plain secret: 1FpqLTlCiXEw8Gxl5ayBGMRvD6Efn2BxtZ5CYSTf5KI=
            client_secret = "$2b$10$sqqdY.dUIvNwdnjWXcN9aO41ZtZ.AaHC2xP.srX/afQsnetM3fEmq";
            public = false;
            authorization_policy = "one_factor";
            claims_policy = "default";

            # Jellyfin SSO plugin uses different auth methods for different endpoints
            token_endpoint_auth_method = "client_secret_post";
            pushed_authorization_request_endpoint_auth_method = "client_secret_basic";

            # Both HTTP and HTTPS redirect URIs - Jellyfin behind reverse proxy may send HTTP
            redirect_uris = [
              "https://jellyfin.${domain}/sso/OID/redirect/authelia"
              "http://jellyfin.${domain}/sso/OID/redirect/authelia"
            ];

            scopes = ["openid" "profile" "groups" "email"];
            response_types = ["code"];
            grant_types = ["authorization_code"];
            response_modes = ["query"];

            userinfo_signed_response_alg = "none";
          }

        ];
      };
    };
  };

  # Copy declarative users.yml to stateDir
  # preStart runs as the service user (authelia-main)
  systemd.services.authelia-main.preStart = ''
    cp -f ${usersYml} ${authelia.stateDir}/users.yml
    chmod 0600 ${authelia.stateDir}/users.yml
  '';
}
