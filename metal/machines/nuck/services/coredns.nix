{config, ...}: let
  commonConfig = import ../../../common-config.nix;
  domain = commonConfig.network.domain;
  tailscaleIP = commonConfig.machines.nuck.tailscaleIp;
  hostname = commonConfig.machines.nuck.hostname;
in {
  # CoreDNS - Custom DNS server for mac.lab domain on tailnet
  # Tailscale DNS handles all other queries as fallback
  services.coredns = {
    enable = true;
    config = ''
      # ${domain} domain - custom tailnet domain
      ${domain} {
        # Static host records
        file /etc/coredns/${domain}.zone

        log
        errors
      }
    '';
  };

  # Create DNS zone file for ${domain}
  environment.etc."coredns/${domain}.zone".text = ''
    $ORIGIN ${domain}.
    @    3600 IN SOA sns.dns.icann.org. noc.dns.icann.org. (
                  2024010101 ; serial
                  7200       ; refresh (2 hours)
                  3600       ; retry (1 hour)
                  1209600    ; expire (2 weeks)
                  3600       ; minimum (1 hour)
                  )

    ; NS records
    @    3600 IN NS ${hostname}.${domain}.

    ; A records for services
    ${hostname}   IN A ${tailscaleIP}
    sso           IN A ${tailscaleIP}
    *.${domain}.  IN A ${tailscaleIP}
  '';

  # Firewall - Open DNS ports
  networking.firewall = {
    allowedTCPPorts = [53];
    allowedUDPPorts = [53];
  };
}
