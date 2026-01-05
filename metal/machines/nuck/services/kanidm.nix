{ vars, pkgs, ... }:
let
  cfg = vars.services.kanidm;

  kanidmConfig = pkgs.writeText "server.toml" ''
    version = "2"

    domain = "${cfg.fqdn}"
    origin = "https://${cfg.fqdn}"
    bindaddress = "0.0.0.0:8443"
    db_path = "/data/kanidm.db"
    tls_chain = "/data/certs/chain.pem"
    tls_key = "/data/certs/key.pem"

    # Trust X-Forwarded-For headers from Caddy reverse proxy (Podman network)
    [http_client_address_info]
    x-forward-for = ["10.88.0.0/16"]
  '';
in
{
  systemd.tmpfiles.rules = [
    "d ${cfg.dataDir} 0750 root root -"
    "d ${cfg.dataDir}/certs 0750 root root -"
  ];

  systemd.services."${cfg.name}-certs" = {
    description = "Generate ${cfg.name} self-signed certificates";
    wantedBy = [ "podman-${cfg.name}.service" ];
    before = [ "podman-${cfg.name}.service" ];
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if [ ! -f ${cfg.dataDir}/certs/key.pem ]; then
        podman run --rm -v ${cfg.dataDir}:/data:Z ${cfg.image} kanidmd cert-generate
      fi
    '';
  };

  virtualisation.oci-containers.containers.${cfg.name} = {
    image = cfg.image;
    ports = [ "${toString cfg.port}:8443" ];
    volumes = [
      "${cfg.dataDir}:/data"
      "${kanidmConfig}:/data/server.toml:ro"
    ];
  };
}
