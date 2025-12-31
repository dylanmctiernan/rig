{...}: {
  # Caddy web server with mac.lab subdomain routing
  services.caddy = {
    enable = true;

    globalConfig = ''
      # Enable local CA for mac.lab certificates
      local_certs
    '';

    virtualHosts = {
      # Authelia at sso.mac.lab
      "sso.mac.lab" = {
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
            output file /var/log/caddy/sso.mac.lab.log
            format json
          }
        '';
      };

      # Root domain landing page
      "nuck.mac.lab" = {
        extraConfig = ''
          tls internal

          respond "mac.lab Services\n\nAvailable:\n- https://sso.mac.lab - Authelia Authentication" 200

          log {
            output file /var/log/caddy/nuck.mac.lab.log
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
