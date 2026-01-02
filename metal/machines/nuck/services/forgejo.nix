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
    discover="https://sso.${domain}/.well-known/openid-configuration"
    key="forgejo"
    secret=$(cat /run/secrets/nuck/authelia/forgejo_oidc_client_secret)

    # Fetch provider ID if it already exists
    # newer Forgejo CLI no longer supports "--type oauth"
    id=$(forgejo admin auth list | awk -v n="$name" '$1==n {print $2}')

    if [ -z "$id" ]; then
      echo "Creating OAuth provider $name"
      forgejo admin auth add-oauth \
        --name "$name" \
        --provider openidConnect \
        --key "$key" \
        --secret "$secret" \
        --auto-discover-url "$discover" \
        --scopes "openid email profile groups" \
        --auto-register
    else
      echo "Updating OAuth provider $name (id=$id)"
      forgejo admin auth update-oauth --id "$id" \
        --key "$key" \
        --secret "$secret" \
        --auto-discover-url "$discover" \
        --scopes "openid email profile groups" \
        --auto-register
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
      webhook = {
        SKIP_TLS_VERIFY = true;
      };

      openid = {
        SKIP_TLS_VERIFY = true;  # Trust internal Caddy CA certificates
      };
    };
  };

  # Idempotent systemd unit to ensure OAuth provider "authelia" exists
  systemd.services."forgejo-upsert-oauth" = {
    description = "Ensure/refresh Forgejo OAuth provider authelia";
    after       = [ "forgejo.service" ];
    requires    = [ "forgejo.service" ];
    wantedBy    = [ "multi-user.target" ];

    serviceConfig = {
      Type            = "oneshot";
      User            = "root";
      WorkingDirectory = "/var/lib/forgejo";

      ExecStart = "${forgejoUpsertScript}";

      # Hardening flags
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;

    };

    restartTriggers = [
      config.sops.secrets."nuck/authelia/forgejo_oidc_client_secret".path
      forgejoUpsertScript
    ];
  };

  # Firewall - Forgejo will be accessed via Caddy reverse proxy
  # No direct external access needed (listens on 127.0.0.1 only)
}
