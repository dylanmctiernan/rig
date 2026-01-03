{ config, pkgs, ... }:
let
  commonConfig = import ../../../common-config.nix;
in
{
  # Nixarr media server stack configuration
  # Documentation: https://nixarr.com/

  nixarr = {
    enable = true;

    # Mullvad VPN for Transmission
    vpn = {
      enable = true;
      wgConf = config.sops.secrets."mullvad/wg_conf".path;
    };

    # Media root - points to NFS mount from Synology NAS
    mediaDir = commonConfig.machines.nuck.mediaDir;

    # State directory for service data (metadata, configs, etc)
    stateDir = "/var/lib/nixarr";

    # Jellyfin - Media server for streaming
    # Note: Jellyfin uses default port 8096 (not configurable via NixOS options)
    jellyfin = {
      enable = true;
      openFirewall = false; # We use Caddy reverse proxy
      stateDir = commonConfig.services.jellyfin.stateDir;
    };

    # Transmission - BitTorrent client
    transmission = {
      enable = true;
      openFirewall = true; # Peer port needs to be open
      uiPort = commonConfig.services.transmission.httpPort;
      peerPort = commonConfig.services.transmission.peerPort;
      stateDir = commonConfig.services.transmission.stateDir;

      # Route Transmission through Mullvad VPN
      vpn.enable = true;

      # Extra settings for reverse proxy access and performance
      extraSettings = {
        rpc-host-whitelist = "transmission.mac.lab";
        rpc-host-whitelist-enabled = true;

        # Remove torrents after seeding completes (ratio of 0 = immediate)
        ratio-limit-enabled = true;
        ratio-limit = 0;
      };
    };

    # Sonarr - TV show management
    sonarr = {
      enable = true;
      openFirewall = false;
      port = commonConfig.services.sonarr.httpPort;
      stateDir = commonConfig.services.sonarr.stateDir;
    };

    # Radarr - Movie management
    radarr = {
      enable = true;
      openFirewall = false;
      port = commonConfig.services.radarr.httpPort;
      stateDir = commonConfig.services.radarr.stateDir;
    };

    # Lidarr - Music management
    lidarr = {
      enable = true;
      openFirewall = false;
      port = commonConfig.services.lidarr.httpPort;
      stateDir = commonConfig.services.lidarr.stateDir;
    };

    # Prowlarr - Indexer manager (handles torrent/usenet indexers for all *arr apps)
    prowlarr = {
      enable = true;
      openFirewall = false;
      port = commonConfig.services.prowlarr.httpPort;
      stateDir = commonConfig.services.prowlarr.stateDir;
    };

    # Bazarr - Subtitle management
    bazarr = {
      enable = true;
      openFirewall = false;
      port = commonConfig.services.bazarr.httpPort;
      stateDir = commonConfig.services.bazarr.stateDir;
    };

    # Jellyseerr - Media request management
    jellyseerr = {
      enable = true;
      openFirewall = false;
      port = commonConfig.services.jellyseerr.httpPort;
      stateDir = commonConfig.services.jellyseerr.stateDir;
    };
  };

  # Transmission peer port not needed on host firewall - traffic goes through VPN namespace

  # WireGuard VPN service can fail at boot if endpoint isn't reachable yet - add restart policy
  systemd.services.wg = {
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "10s";
    };
    unitConfig = {
      StartLimitIntervalSec = "300";
      StartLimitBurst = "10";
    };
  };

  # Grant Jellyfin access to GPU for hardware transcoding (Intel Quick Sync)
  users.users.jellyfin.extraGroups = [
    "video"
    "render"
  ];

  # Pinchflat - YouTube content downloader
  # Downloads YouTube videos from channels/playlists on a schedule
  # Documentation: https://github.com/kieraneglin/pinchflat

  environment.systemPackages = [ pkgs.pinchflat ];

  users.users.pinchflat = {
    isSystemUser = true;
    group = "pinchflat";
    home = commonConfig.services.pinchflat.stateDir;
    createHome = true;
  };

  users.groups.pinchflat = { };

  systemd.services.pinchflat = {
    description = "Pinchflat - YouTube content downloader";
    after = [
      "network.target"
      "mnt-media.mount"
    ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = "pinchflat";
      Group = "pinchflat";
      WorkingDirectory = commonConfig.services.pinchflat.stateDir;

      Environment = [
        "PORT=${toString commonConfig.services.pinchflat.httpPort}"
        "ENABLE_PROMETHEUS=true"
        "TZ=America/New_York"
      ];

      ExecStart = "${pkgs.pinchflat}/bin/pinchflat start";

      Restart = "on-failure";
      RestartSec = "10s";

      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [
        commonConfig.services.pinchflat.stateDir
        "${commonConfig.machines.nuck.mediaDir}/youtube"
      ];
    };
  };
}
