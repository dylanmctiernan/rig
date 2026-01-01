{
  config,
  pkgs,
  ...
}: let
  commonConfig = import ../../../common-config.nix;
  domain = commonConfig.network.domain;
  backrestPort = 9898;
in {
  # Backrest - Web UI for restic backups

  # Install backrest package
  environment.systemPackages = [pkgs.backrest];

  # Create backrest user and group
  users.users.backrest = {
    isSystemUser = true;
    group = "backrest";
    home = "/var/lib/backrest";
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
      WorkingDirectory = "/var/lib/backrest";

      # Environment variables for backrest configuration
      Environment = [
        "BACKREST_DATA=/var/lib/backrest"
        "BACKREST_CONFIG=/var/lib/backrest/config.json"
        "XDG_CACHE_HOME=/var/lib/backrest/.cache"
      ];

      ExecStart = "${pkgs.backrest}/bin/backrest --bind-address 127.0.0.1:${toString backrestPort}";

      Restart = "on-failure";
      RestartSec = "10s";

      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = ["/var/lib/backrest"];
    };
  };

  # Ensure backrest data directory exists with correct permissions
  systemd.tmpfiles.rules = [
    "d /var/lib/backrest 0750 backrest backrest -"
    "d /var/lib/backrest/.cache 0750 backrest backrest -"
  ];

  # Firewall - Backrest will be accessed via Caddy reverse proxy
  # No direct external access needed (listens on 127.0.0.1 only)
}
