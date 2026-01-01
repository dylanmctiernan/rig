{
  config,
  pkgs,
  lib,
  ...
}: let
  commonConfig = import ../../../common-config.nix;
  domain = commonConfig.network.domain;
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

      # Allow insecure OAuth2 connections (for internal Caddy CA)
      webhook = {
        SKIP_TLS_VERIFY = true;
      };
    };

    # Note: OAuth2 providers must be added via CLI or web UI:
    # forgejo admin auth add-oauth \
    #   --name authelia \
    #   --provider openidConnect \
    #   --key forgejo \
    #   --secret <client-secret> \
    #   --auto-discover-url https://sso.${domain}/.well-known/openid-configuration \
    #   --scopes "openid email profile groups"
  };

  # Firewall - Forgejo will be accessed via Caddy reverse proxy
  # No direct external access needed (listens on 127.0.0.1 only)
}
