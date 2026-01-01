{
  config,
  pkgs,
  lib,
  ...
}: let
  commonConfig = import ../../../../common-config.nix;
  domain = commonConfig.network.domain;
  grafana = commonConfig.lgtm.grafana;
  loki = commonConfig.lgtm.loki;
  tempo = commonConfig.lgtm.tempo;
  mimir = commonConfig.lgtm.mimir;
in {
  services.grafana = {
    enable = true;

    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = grafana.httpPort;
        domain = "grafana.${domain}";
        root_url = "https://grafana.${domain}/";
      };

      security = {
        admin_user = "admin";
        admin_password = "$__file{/var/lib/grafana/admin_password}";
        secret_key = "$__file{/var/lib/grafana/secret_key}";
      };

      # Authelia OIDC SSO
      "auth.generic_oauth" = {
        enabled = true;
        name = "Authelia";
        client_id = "grafana";
        client_secret = "$__file{${config.sops.secrets."nuck/authelia/grafana_client_secret".path}}";
        scopes = "openid profile email groups";
        auth_url = "https://sso.${domain}/api/oidc/authorization";
        token_url = "https://sso.${domain}/api/oidc/token";
        api_url = "https://sso.${domain}/api/oidc/userinfo";
        use_pkce = true;
        use_refresh_token = true;

        # Role mapping
        role_attribute_path = "contains(groups[*], 'admins') && 'Admin' || 'Viewer'";

        # Auto login (optional - comment out if you want login button)
        # auto_login = true;

        # Allow sign up
        allow_sign_up = true;

        # TLS settings for internal CA
        tls_skip_verify_insecure = true;
      };

      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
      };

      log = {
        mode = "console file";
        level = "info";
      };

      # Enable Grafana Alloy integration
      "feature_toggles" = {
        enable = "lokiLogsDataplane";
      };
    };

    # Provision datasources automatically
    provision = {
      enable = true;

      datasources.settings = {
        apiVersion = 1;
        datasources = [
          {
            name = "Loki";
            type = "loki";
            access = "proxy";
            url = "http://127.0.0.1:${toString loki.httpPort}";
            isDefault = true;
            jsonData = {
              maxLines = 1000;
            };
          }
          {
            name = "Tempo";
            type = "tempo";
            access = "proxy";
            url = "http://127.0.0.1:${toString tempo.httpPort}";
            jsonData = {
              httpMethod = "GET";
              tracesToLogsV2 = {
                datasourceUid = "Loki";
                spanStartTimeShift = "1h";
                spanEndTimeShift = "-1h";
                filterByTraceID = true;
              };
            };
          }
          {
            name = "Mimir";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:${toString mimir.httpPort}/prometheus";
            isDefault = false;
            jsonData = {
              httpMethod = "POST";
              prometheusType = "Mimir";
            };
          }
        ];
      };

      dashboards.settings = {
        apiVersion = 1;
        providers = [
          {
            name = "default";
            orgId = 1;
            folder = "";
            type = "file";
            disableDeletion = false;
            updateIntervalSeconds = 10;
            allowUiUpdates = true;
            options = {
              path = "/var/lib/grafana/dashboards";
            };
          }
        ];
      };
    };
  };

  # Create necessary directories and secrets
  systemd.tmpfiles.rules = [
    "d /var/lib/grafana 0750 grafana grafana -"
    "d /var/lib/grafana/dashboards 0750 grafana grafana -"
  ];

  # Generate admin password if it doesn't exist
  systemd.services.grafana-init-secrets = {
    description = "Initialize Grafana secrets";
    wantedBy = [ "multi-user.target" ];
    before = [ "grafana.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if [ ! -f /var/lib/grafana/admin_password ]; then
        ${pkgs.pwgen}/bin/pwgen -s 32 1 > /var/lib/grafana/admin_password
        chown grafana:grafana /var/lib/grafana/admin_password
        chmod 0600 /var/lib/grafana/admin_password
      fi
      if [ ! -f /var/lib/grafana/secret_key ]; then
        ${pkgs.pwgen}/bin/pwgen -s 32 1 > /var/lib/grafana/secret_key
        chown grafana:grafana /var/lib/grafana/secret_key
        chmod 0600 /var/lib/grafana/secret_key
      fi
    '';
  };
}
