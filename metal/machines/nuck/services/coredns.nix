{config, ...}: let
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

  # Firewall - Open DNS ports
  networking.firewall = {
    allowedTCPPorts = [53];
    allowedUDPPorts = [53];
  };
}
