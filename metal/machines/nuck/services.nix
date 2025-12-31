{
  config,
  pkgs,
  ...
}: let
  # Tailscale IP for nuck
  tailscaleIP = "100.114.41.97";
in {
  # CoreDNS - Custom DNS server for mac.lab domain on tailnet
  services.coredns = {
    enable = true;
    config = ''
      # mac.lab domain - custom tailnet domain
      mac.lab {
        # Static host records
        file /etc/coredns/mac.lab.zone

        log
        errors
      }

      # Forward all other queries to Tailscale DNS and public resolvers
      . {
        forward . 100.100.100.100 1.1.1.1
        log
        errors
        cache 30
      }
    '';
  };

  # Create DNS zone file for mac.lab
  environment.etc."coredns/mac.lab.zone".text = ''
    $ORIGIN mac.lab.
    @    3600 IN SOA sns.dns.icann.org. noc.dns.icann.org. (
                  2024010101 ; serial
                  7200       ; refresh (2 hours)
                  3600       ; retry (1 hour)
                  1209600    ; expire (2 weeks)
                  3600       ; minimum (1 hour)
                  )

    ; NS records
    @    3600 IN NS nuck.mac.lab.

    ; A records for services
    nuck          IN A ${tailscaleIP}
    sso           IN A ${tailscaleIP}
    *.mac.lab.    IN A ${tailscaleIP}
  '';

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

  # Firewall - Open DNS and HTTPS ports
  networking.firewall = {
    allowedTCPPorts = [ 53 443 ];
    allowedUDPPorts = [ 53 ];
  };

  # Authelia - Authentication and authorization server
  services.authelia.instances.main = {
    enable = true;

    secrets = {
      jwtSecretFile = "/var/lib/authelia-main/secrets/jwt";
      storageEncryptionKeyFile = "/var/lib/authelia-main/secrets/storage-encryption-key";
      sessionSecretFile = "/var/lib/authelia-main/secrets/session";
    };

    settings = {
      theme = "auto";
      default_2fa_method = "totp";

      log = {
        level = "info";
        format = "json";
      };

      # Listen on localhost - behind Caddy
      server = {
        address = "tcp://127.0.0.1:9091";
        endpoints.authz.forward-auth.implementation = "ForwardAuth";
      };

      # Session for mac.lab domain
      session = {
        domain = "mac.lab";
        same_site = "lax";
        expiration = "1h";
        inactivity = "5m";
      };

      storage.local.path = "/var/lib/authelia-main/db.sqlite3";

      # Access control for mac.lab
      access_control = {
        default_policy = "one_factor";
        rules = [
          {
            domain = "mac.lab";
            policy = "one_factor";
          }
          {
            domain = "*.mac.lab";
            policy = "one_factor";
          }
        ];
      };

      notifier.filesystem = {
        filename = "/var/lib/authelia-main/notifications.txt";
      };

      authentication_backend.file = {
        path = "/var/lib/authelia-main/users.yml";
      };
    };
  };
}
