{
  config,
  pkgs,
  lib,
  ...
}:
let
  commonConfig = import ../../../../common-config.nix;
  domain = commonConfig.network.domain;
  grafana = commonConfig.lgtm.grafana;
  loki = commonConfig.lgtm.loki;
  tempo = commonConfig.lgtm.tempo;
  mimir = commonConfig.lgtm.mimir;

  # Exportarr dashboard from upstream, patched to use our Mimir datasource
  exportarrDashboard = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/onedr0p/exportarr/master/examples/grafana/dashboard2.json";
    sha256 = "0sgry76hl5qp9fnz9picmyns5b59kyvn7m41zx2vgspfad85ypmh";
  };
in
{
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
        admin_password = "$__file{${grafana.stateDir}/admin_password}";
        secret_key = "$__file{${grafana.stateDir}/secret_key}";
      };

      # Authelia OIDC SSO
      "auth.generic_oauth" = {
        enabled = true;
        name = "Authelia";
        client_id = "grafana";
        client_secret = "$__file{/run/secrets/nuck/authelia/grafana_oidc_client_secret}";
        scopes = "openid profile email groups";
        auth_url = "https://sso.${domain}/api/oidc/authorization";
        token_url = "https://sso.${domain}/api/oidc/token";
        api_url = "https://sso.${domain}/api/oidc/userinfo";
        use_pkce = true;
        use_refresh_token = true;

        # Force client_secret_basic authentication (InHeader)
        auth_style = "InHeader";

        # Role mapping - users in 'admins' group get Admin role
        role_attribute_path = "contains(groups[*], 'admins') && 'Admin' || 'Editor'";
        role_attribute_strict = false;

        # Allow assigning grafana admin role
        allow_assign_grafana_admin = true;
        skip_org_role_sync = false;

        # Auto login (optional - comment out if you want login button)
        # auto_login = true;

        # Allow sign up
        allow_sign_up = true;

        # TLS settings for internal CA
        tls_skip_verify_insecure = true;
      };

      # Users settings - auto-assign admin to OAuth users in admins group
      users = {
        auto_assign_org = true;
        auto_assign_org_id = 1;
        auto_assign_org_role = "Editor";
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

      datasources.settings.datasources = [
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

      dashboards.settings.providers = [
        {
          name = "default";
          orgId = 1;
          folder = "";
          type = "file";
          disableDeletion = false;
          updateIntervalSeconds = 10;
          allowUiUpdates = true;
          options = {
            path = "${grafana.stateDir}/dashboards";
          };
        }
        {
          name = "exportarr";
          orgId = 1;
          folder = "Exportarr";
          type = "file";
          disableDeletion = false;
          updateIntervalSeconds = 60;
          allowUiUpdates = false;
          options = {
            path = "${grafana.stateDir}/dashboards/exportarr";
          };
        }
      ];
    };
  };

  # Create necessary directories and secrets
  systemd.tmpfiles.rules = [
    "d ${grafana.stateDir}/dashboards 0750 grafana grafana -"
    "d ${grafana.stateDir}/dashboards/exportarr 0750 grafana grafana -"
  ];

  # Copy and patch exportarr dashboard to use Mimir datasource
  systemd.services.grafana-provision-exportarr = {
    description = "Provision exportarr Grafana dashboard";
    wantedBy = [ "multi-user.target" ];
    before = [ "grafana.service" ];
    after = [ "grafana-init-secrets.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Patch the dashboard to use our Mimir datasource by name
      ${pkgs.gnused}/bin/sed 's/"type": "prometheus"/"type": "prometheus", "uid": "Mimir"/g' \
        ${exportarrDashboard} > ${grafana.stateDir}/dashboards/exportarr/media.json
      chown grafana:grafana ${grafana.stateDir}/dashboards/exportarr/media.json
      chmod 0640 ${grafana.stateDir}/dashboards/exportarr/media.json
    '';
  };

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
      if [ ! -f ${grafana.stateDir}/admin_password ]; then
        ${pkgs.pwgen}/bin/pwgen -s 32 1 > ${grafana.stateDir}/admin_password
        chown grafana:grafana ${grafana.stateDir}/admin_password
        chmod 0600 ${grafana.stateDir}/admin_password
      fi
      if [ ! -f ${grafana.stateDir}/secret_key ]; then
        ${pkgs.pwgen}/bin/pwgen -s 32 1 > ${grafana.stateDir}/secret_key
        chown grafana:grafana ${grafana.stateDir}/secret_key
        chmod 0600 ${grafana.stateDir}/secret_key
      fi
    '';
  };

  # Ensure grafana service can read the OIDC secret (owned by authelia-main:grafana)
  systemd.services.grafana = {
    serviceConfig = {
      SupplementaryGroups = [ "grafana" ];
    };
  };
}
