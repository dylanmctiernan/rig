{ vars, ... }:
{
  services.caddy = {
    enable = true;
    virtualHosts."${vars.services.kanidm.fqdn}" = {
      extraConfig = ''
        tls internal
        reverse_proxy https://127.0.0.1:${toString vars.services.kanidm.port} {
          transport http {
            tls_insecure_skip_verify
          }
        }
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
