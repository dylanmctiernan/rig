{ vars, pkgs, ... }:
let
  kanidmPort = vars.services.kanidm.port;
  dataDir = "/data/kanidm";

  kanidmConfig = pkgs.writeText "server.toml" ''
    domain = "${vars.services.kanidm.fqdn}"
    origin = "https://${vars.services.kanidm.fqdn}"
    bindaddress = "0.0.0.0:8443"
    db_path = "/data/kanidm.db"
    tls_chain = "/data/certs/chain.pem"
    tls_key = "/data/certs/key.pem"
  '';
in
{
  # Ensure data directory and generate self-signed certs
  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 root root -"
    "d ${dataDir}/certs 0750 root root -"
  ];

  # Generate self-signed certs if they don't exist
  systemd.services.kanidm-certs = {
    description = "Generate Kanidm self-signed certificates";
    wantedBy = [ "podman-kanidm.service" ];
    before = [ "podman-kanidm.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if [ ! -f ${dataDir}/certs/key.pem ]; then
        ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:4096 \
          -keyout ${dataDir}/certs/key.pem \
          -out ${dataDir}/certs/chain.pem \
          -days 365 -nodes \
          -subj "/CN=${vars.services.kanidm.fqdn}"
      fi
    '';
  };

  virtualisation.oci-containers.containers.kanidm = {
    image = "kanidm/server:latest";
    ports = [ "127.0.0.1:${toString kanidmPort}:8443" ];
    volumes = [
      "${dataDir}:/data"
      "${kanidmConfig}:/data/server.toml:ro"
    ];
  };
}
