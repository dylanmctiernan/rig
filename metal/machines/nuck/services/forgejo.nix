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
        DISABLE_REGISTRATION = true;  # Only allow SSO registration
        REQUIRE_SIGNIN_VIEW = false;   # Allow public repo viewing
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

      # OpenID Connect (OIDC) configuration will be done via Authelia
      # OAuth2 configuration is handled through web UI or CLI after deployment
    };
  };

  # Firewall - Forgejo will be accessed via Caddy reverse proxy
  # No direct external access needed (listens on 127.0.0.1 only)
}
