{pkgs, ...}: let
  commonConfig = import ../../../common-config.nix;
  domain = commonConfig.network.domain;
  uptimeKuma = commonConfig.services.uptimeKuma;
in {
  # Uptime Kuma - Uptime monitoring and status page

  environment.systemPackages = [pkgs.uptime-kuma];

  # Create uptime-kuma user and group
  users.users.uptime-kuma = {
    isSystemUser = true;
    group = "uptime-kuma";
    home = uptimeKuma.stateDir;
    createHome = true;
  };

  users.groups.uptime-kuma = {};

  # Uptime Kuma systemd service
  systemd.services.uptime-kuma = {
    description = "Uptime Kuma - Uptime monitoring and status page";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "simple";
      User = "uptime-kuma";
      Group = "uptime-kuma";
      WorkingDirectory = uptimeKuma.stateDir;

      Environment = [
        "DATA_DIR=${uptimeKuma.stateDir}"
        "UPTIME_KUMA_HOST=127.0.0.1"
        "UPTIME_KUMA_PORT=${toString uptimeKuma.httpPort}"
      ];

      ExecStart = "${pkgs.uptime-kuma}/bin/uptime-kuma-server";

      Restart = "on-failure";
      RestartSec = "10s";

      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [uptimeKuma.stateDir];
    };
  };

  # Firewall - Uptime Kuma will be accessed via Caddy reverse proxy
  # No direct external access needed (listens on 127.0.0.1 only)
}
