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

    # Skip TLS verification for internal CA
    export GIT_SSL_NO_VERIFY=true

    name="authelia"
    key="forgejo"
    secret=$(cat /run/secrets/nuck/authelia/forgejo_oidc_client_secret)

    # Use explicit HTTPS endpoints instead of auto-discovery
    auth_url="https://sso.${domain}/api/oidc/authorization"
    token_url="https://sso.${domain}/api/oidc/token"
    profile_url="https://sso.${domain}/api/oidc/userinfo"

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
        --use-custom-urls "true" \
        --custom-auth-url "$auth_url" \
        --custom-token-url "$token_url" \
        --custom-profile-url "$profile_url" \
        --scopes "openid email profile groups" \
        --skip-local-2fa
    else
      echo "Updating OAuth provider $name (id=$id)"
      forgejo --config "$config" admin auth update-oauth --id "$id" \
        --key "$key" \
        --secret "$secret" \
        --use-custom-urls "true" \
        --custom-auth-url "$auth_url" \
        --custom-token-url "$token_url" \
        --custom-profile-url "$profile_url" \
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

    restartTriggers = [
      config.sops.secrets."nuck/authelia/forgejo_oidc_client_secret".path
      forgejoUpsertScript
    ];
  };

  # Firewall - Forgejo will be accessed via Caddy reverse proxy
  # No direct external access needed (listens on 127.0.0.1 only)
}
