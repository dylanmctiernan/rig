{
  vars,
  pkgs,
  config,
  ...
}:
let
  cfg = vars.services.kanidm;
  containerBackend = config.virtualisation.oci-containers.backend;
  containerServiceName = "${containerBackend}-${cfg.name}";

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

  # Generate certs on first boot if they don't exist
  systemd.services."${cfg.name}-certs-bootstrap" = {
    description = "Bootstrap ${cfg.name} self-signed certificates";
    wantedBy = [ "${containerServiceName}.service" ];
    before = [ "${containerServiceName}.service" ];
    path = [ pkgs.${containerBackend} ];
    serviceConfig.Type = "oneshot";
    script = ''
      if [ -z "$(ls -A ${cfg.dataDir}/certs)" ]; then
        ${containerBackend} run --rm -v ${cfg.dataDir}:/data:Z -v ${kanidmConfig}:/data/server.toml:ro ${cfg.image} kanidmd cert-generate
      fi
    '';
  };

  # Daily cert regeneration (separate service to avoid deadlock with before/restart)
  systemd.services."${cfg.name}-certs-renew" = {
    description = "Renew ${cfg.name} certificates and restart";
    path = [ pkgs.${containerBackend} ];
    serviceConfig.Type = "oneshot";
    script = ''
      rm -f ${cfg.dataDir}/certs/*.pem
      ${containerBackend} run --rm -v ${cfg.dataDir}:/data:Z -v ${kanidmConfig}:/data/server.toml:ro ${cfg.image} kanidmd cert-generate
      systemctl restart ${containerServiceName}
    '';
  };

  systemd.timers."${cfg.name}-certs-renew" = {
    description = "Daily ${cfg.name} certificate renewal";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
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
