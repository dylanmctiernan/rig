{
  pkgs,
  ...
}: let
  commonConfig = import ../../../common-config.nix;
  backrest = commonConfig.services.backrest;
in {
  # Backrest - Web UI for restic backups

  # Install backrest package
  environment.systemPackages = [pkgs.backrest];

  # Create backrest user and group
  users.users.backrest = {
    isSystemUser = true;
    group = "backrest";
    home = backrest.stateDir;
    createHome = true;
  };

  users.groups.backrest = {};

  # Backrest systemd service
  systemd.services.backrest = {
    description = "Backrest - Web UI and orchestrator for restic backup";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "simple";
      User = "backrest";
      Group = "backrest";
      WorkingDirectory = backrest.stateDir;

      # Environment variables for backrest configuration
      Environment = [
        "BACKREST_DATA=${backrest.stateDir}"
        "BACKREST_CONFIG=${backrest.stateDir}/config.json"
        "XDG_CACHE_HOME=${backrest.stateDir}/.cache"
      ];

      ExecStart = "${pkgs.backrest}/bin/backrest --bind-address 127.0.0.1:${toString backrest.httpPort}";

      Restart = "on-failure";
      RestartSec = "10s";

      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [backrest.stateDir];
    };
  };

  # Firewall - Backrest will be accessed via Caddy reverse proxy
  # No direct external access needed (listens on 127.0.0.1 only)
}
