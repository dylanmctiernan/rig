{ vars, pkgs, ... }:
let
  cfg = vars.services.caddy;
  kanidm = vars.services.kanidm;

  caddyfile = pkgs.writeText "Caddyfile" ''
    ${kanidm.fqdn} {
      # TODO: Change when we have public LE certs
      tls internal
      reverse_proxy https://${kanidm.name}:${toString kanidm.port} {
        transport http {
          tls_insecure_skip_verify
        }
      }
    }
  '';
in
{
  systemd.tmpfiles.rules = [
    "d ${cfg.dataDir} 0755 root root -"
    "d ${cfg.dataDir}/data 0755 root root -"
    "d ${cfg.dataDir}/config 0755 root root -"
  ];

  virtualisation.oci-containers.containers.${cfg.name} = {
    image = cfg.image;
    ports = [
      "80:80"
      "443:443"
    ];
    volumes = [
      "${caddyfile}:/etc/caddy/Caddyfile:ro"
      "${cfg.dataDir}/data:/data"
      "${cfg.dataDir}/config:/config"
    ];
    dependsOn = [ kanidm.name ];
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
