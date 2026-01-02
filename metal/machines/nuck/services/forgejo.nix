{
  config,
  pkgs,
  ...
}: let
  commonConfig = import ../../../common-config.nix;
  domain = commonConfig.network.domain;
  forgejo = commonConfig.services.forgejo;
in {
  # Forgejo - Self-hosted Git service
  services.forgejo = {
    enable = true;

    # Use SQLite with WAL mode for better performance
    database = {
      type = "sqlite3";
    };

    # SQLite performance optimization
    settings.database = {
      SQLITE_JOURNAL_MODE = "WAL";  # Write-Ahead Logging for better concurrency
    };

    # Enable Git LFS for large file support
    lfs.enable = true;

    settings = {
      server = {
        DOMAIN = "${forgejo.subdomain}.${domain}";
        ROOT_URL = "https://${forgejo.subdomain}.${domain}/";
        HTTP_PORT = forgejo.httpPort;
        HTTP_ADDR = "127.0.0.1";
        ENABLE_PPROF = true;  # Enable profiling endpoint for metrics
      };

      log = {
        MODE = "console";  # Log to stdout for journald collection
        LEVEL = "Info";
        "logger.router.MODE" = "console";
        "logger.access.MODE" = "console";
      };

      metrics = {
        ENABLED = true;
        TOKEN = "";  # No authentication for internal metrics endpoint
      };

      service = {
        DISABLE_REGISTRATION = false;  # Allow SSO registration via OIDC
        REQUIRE_SIGNIN_VIEW = false;   # Allow public repo viewing
        ALLOW_ONLY_EXTERNAL_REGISTRATION = true;  # Force OIDC registration
      };

      # Enable Actions for CI/CD
      actions = {
        ENABLED = true;
        DEFAULT_ACTIONS_URL = "github";
      };

      # Session and security
      session = {
        COOKIE_SECURE = true;
        SAME_SITE = "lax";
      };

      # OAuth2 / OIDC configuration for Authelia SSO
      "oauth2_client" = {
        ACCOUNT_LINKING = "auto";  # Auto-link accounts by email
        ENABLE_AUTO_REGISTRATION = true;
        USERNAME = "preferred_username";
        UPDATE_AVATAR = true;
      };

      # Allow insecure connections for internal Caddy CA
      http = {
        SKIP_TLS_VERIFY = true;  # Skip TLS verification globally for internal CA
      };

      webhook = {
        SKIP_TLS_VERIFY = true;
      };

      openid = {
        SKIP_TLS_VERIFY = true;  # Trust internal Caddy CA certificates
      };
    };
  };

  # Create combined CA bundle with system CAs + Caddy CA
  systemd.services.copy-caddy-ca = {
    description = "Create combined CA bundle for Forgejo";
    after = [ "caddy.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "copy-caddy-ca" ''
        mkdir -p /etc/forgejo/certs
        # Combine system CA bundle with Caddy CA
        cat ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt > /etc/forgejo/certs/ca-bundle.crt
        cat /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt >> /etc/forgejo/certs/ca-bundle.crt
        chmod 644 /etc/forgejo/certs/ca-bundle.crt
      '';
    };
  };

  # Use combined CA bundle for Forgejo
  systemd.services.forgejo = {
    after = [ "copy-caddy-ca.service" ];
    requires = [ "copy-caddy-ca.service" ];
    environment = {
      SSL_CERT_FILE = "/etc/forgejo/certs/ca-bundle.crt";
    };
  };

  # Firewall - Forgejo will be accessed via Caddy reverse proxy
  # No direct external access needed (listens on 127.0.0.1 only)
}
