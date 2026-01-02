{...}: let
  commonConfig = import ../../../common-config.nix;
  domain = commonConfig.network.domain;
  hostname = commonConfig.machines.nuck.hostname;

  # Service references
  authelia = commonConfig.infrastructure.authelia;
  forgejo = commonConfig.services.forgejo;
  backrest = commonConfig.services.backrest;
  uptimeKuma = commonConfig.services.uptimeKuma;
  grafana = commonConfig.lgtm.grafana;
in {
  # Caddy web server with ${domain} subdomain routing
  services.caddy = {
    enable = true;

    globalConfig = ''
      # Enable local CA for ${domain} certificates
      local_certs
    '';

    virtualHosts = {
      # Authelia at sso.${domain}
      "${authelia.subdomain}.${domain}" = {
        extraConfig = ''
          # Caddy will auto-generate certs with internal CA
          tls internal

          reverse_proxy localhost:${toString authelia.httpPort}

          # Security headers
          header {
            Strict-Transport-Security "max-age=31536000"
            X-Frame-Options "DENY"
            X-Content-Type-Options "nosniff"
            -Server
          }

          log {
            output file /var/log/caddy/sso.${domain}.log
            format json
          }
        '';
      };

      # Backrest at backup.${domain}
      "${backrest.subdomain}.${domain}" = {
        extraConfig = ''
          tls internal

          # Authelia forward auth
          forward_auth localhost:${toString authelia.httpPort} {
            uri /api/authz/forward-auth
            copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
          }

          reverse_proxy localhost:${toString backrest.httpPort}

          # Security headers
          header {
            Strict-Transport-Security "max-age=31536000"
            X-Frame-Options "SAMEORIGIN"
            X-Content-Type-Options "nosniff"
            -Server
          }

          log {
            output file /var/log/caddy/backup.${domain}.log
            format json
          }
        '';
      };

      # Forgejo at git.${domain}
      "${forgejo.subdomain}.${domain}" = {
        extraConfig = ''
          tls internal

          reverse_proxy localhost:${toString forgejo.httpPort}

          # Security headers
          header {
            Strict-Transport-Security "max-age=31536000"
            X-Frame-Options "SAMEORIGIN"
            X-Content-Type-Options "nosniff"
            -Server
          }

          log {
            output file /var/log/caddy/git.${domain}.log
            format json
          }
        '';
      };

      # Grafana at grafana.${domain}
      "${grafana.subdomain}.${domain}" = {
        extraConfig = ''
          tls internal

          reverse_proxy localhost:${toString grafana.httpPort}

          # Security headers
          header {
            Strict-Transport-Security "max-age=31536000"
            X-Frame-Options "SAMEORIGIN"
            X-Content-Type-Options "nosniff"
            -Server
          }

          log {
            output file /var/log/caddy/grafana.${domain}.log
            format json
          }
        '';
      };

      # Uptime Kuma at status.${domain}
      "${uptimeKuma.subdomain}.${domain}" = {
        extraConfig = ''
          tls internal

          reverse_proxy localhost:${toString uptimeKuma.httpPort}

          # Security headers
          header {
            Strict-Transport-Security "max-age=31536000"
            X-Frame-Options "SAMEORIGIN"
            X-Content-Type-Options "nosniff"
            -Server
          }

          log {
            output file /var/log/caddy/status.${domain}.log
            format json
          }
        '';
      };

      # Root domain landing page
      "${hostname}.${domain}" = {
        extraConfig = ''
          tls internal

          respond "${domain} Services\n\nAvailable:\n- https://sso.${domain} - Authelia Authentication\n- https://backup.${domain} - Backrest Backup UI\n- https://git.${domain} - Forgejo Git Repository\n- https://grafana.${domain} - Grafana Observability\n- https://status.${domain} - Uptime Kuma Monitoring" 200

          log {
            output file /var/log/caddy/${hostname}.${domain}.log
            format json
          }
        '';
      };
    };
  };

  # Ensure Caddy log directory exists
  systemd.tmpfiles.rules = [
    "d /var/log/caddy 0750 caddy caddy -"
  ];

  # Firewall - Open HTTPS port
  networking.firewall.allowedTCPPorts = [443];
}
