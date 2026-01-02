{
  config,
  pkgs,
  lib,
  ...
}: let
  commonConfig = import ../../../common-config.nix;
  domain = commonConfig.network.domain;
  forgejoUpsertScript = pkgs.writeShellScript "forgejo-upsert-oauth" ''
    set -euo pipefail
    # need awk inside PATH as well
    PATH=${pkgs.forgejo}/bin:${pkgs.gawk}/bin:$PATH

    name="authelia"
    key="forgejo"
    secret=$(cat /run/secrets/nuck/authelia/forgejo_oidc_client_secret)

    # Use HTTPS discovery URL (SSL_CERT_FILE env var points to Caddy CA)
    discover_url="https://sso.${domain}/.well-known/openid-configuration"

    # Config file location
    config="/var/lib/forgejo/custom/conf/app.ini"

    # Fetch provider ID if it already exists
    # Format: ID<tab>Name<tab>Type<tab>Enabled
    # Skip header row and match on Name column ($2)
    id=$(forgejo --config "$config" admin auth list | awk -v n="$name" 'NR>1 && $2==n {print $1}')

    if [ -z "$id" ]; then
      echo "Creating OAuth provider $name"
      forgejo --config "$config" admin auth add-oauth \
        --name "$name" \
        --provider openidConnect \
        --key "$key" \
        --secret "$secret" \
        --auto-discover-url "$discover_url" \
        --scopes "openid email profile groups" \
        --skip-local-2fa

      # Get the ID of the newly created provider
      id=$(forgejo --config "$config" admin auth list | awk -v n="$name" 'NR>1 && $2==n {print $1}')
    else
      echo "Updating OAuth provider $name (id=$id)"
      forgejo --config "$config" admin auth update-oauth --id "$id" \
        --key "$key" \
        --secret "$secret" \
        --auto-discover-url "$discover_url" \
        --scopes "openid email profile groups" \
        --skip-local-2fa
    fi
  '';
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
        DOMAIN = "git.${domain}";
        ROOT_URL = "https://git.${domain}/";
        HTTP_PORT = 3000;
        HTTP_ADDR = "127.0.0.1";
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

  # Copy Caddy CA cert to a location readable by forgejo
  systemd.services.copy-caddy-ca = {
    description = "Copy Caddy CA certificate for Forgejo";
    after = [ "caddy.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "copy-caddy-ca" ''
        mkdir -p /etc/forgejo/certs
        cp /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt /etc/forgejo/certs/caddy-ca.crt
        chmod 644 /etc/forgejo/certs/caddy-ca.crt
      '';
    };
  };

  # Add Caddy CA to system trust store for Forgejo
  systemd.services.forgejo = {
    after = [ "copy-caddy-ca.service" ];
    requires = [ "copy-caddy-ca.service" ];
    environment = {
      SSL_CERT_FILE = "/etc/forgejo/certs/caddy-ca.crt";
    };
  };

  # Idempotent systemd unit to ensure OAuth provider "authelia" exists
  systemd.services."forgejo-upsert-oauth" = {
    description = "Ensure/refresh Forgejo OAuth provider authelia";
    after       = [ "forgejo.service" "copy-caddy-ca.service" ];
    requires    = [ "forgejo.service" "copy-caddy-ca.service" ];
    wantedBy    = [ "multi-user.target" ];

    serviceConfig = {
      Type            = "oneshot";
      User            = "forgejo";
      Group           = "forgejo";
      WorkingDirectory = "/var/lib/forgejo";

      ExecStart = "${forgejoUpsertScript}";

      # Capture output
      StandardOutput = "journal";
      StandardError = "journal";

      # Hardening flags (relaxed to allow database writes)
      ReadWritePaths = [ "/var/lib/forgejo" ];
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;

    };

    environment = {
      SSL_CERT_FILE = "/etc/forgejo/certs/caddy-ca.crt";
    };

    restartTriggers = [
      config.sops.secrets."nuck/authelia/forgejo_oidc_client_secret".path
      forgejoUpsertScript
    ];
  };

  # Firewall - Forgejo will be accessed via Caddy reverse proxy
  # No direct external access needed (listens on 127.0.0.1 only)
}
