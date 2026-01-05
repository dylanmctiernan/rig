{ vars, pkgs, ... }:
let
  kanidmPort = vars.services.kanidm.port;
  dataDir = "/data/kanidm";
in
{
  # Ensure data directory exists
  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 root root -"
  ];

  virtualisation.oci-containers.containers.kanidm = {
    image = "kanidm/server:latest";
    ports = [ "127.0.0.1:${toString kanidmPort}:8443" ];
    volumes = [
      "${dataDir}:/data"
    ];
    environment = {
      KANIDM_DOMAIN = vars.services.kanidm.fqdn;
      KANIDM_ORIGIN = "https://${vars.services.kanidm.fqdn}";
    };
  };
}
