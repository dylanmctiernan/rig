{...}: let
  commonConfig = import ../../../common-config.nix;
  domain = commonConfig.network.domain;
  hostname = commonConfig.machines.nuck.hostname;
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
      "sso.${domain}" = {
        extraConfig = ''
          # Caddy will auto-generate certs with internal CA
          tls internal

          reverse_proxy localhost:9091

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
      "backup.${domain}" = {
        extraConfig = ''
          tls internal

          # Authelia forward auth
          forward_auth localhost:9091 {
            uri /api/authz/forward-auth
            copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
          }

          reverse_proxy localhost:9898

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

      # Root domain landing page
      "${hostname}.${domain}" = {
        extraConfig = ''
          tls internal

          respond "${domain} Services\n\nAvailable:\n- https://sso.${domain} - Authelia Authentication\n- https://backup.${domain} - Backrest Backup UI" 200

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
