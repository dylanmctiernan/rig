{ config, ... }:
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

        # Conservative limits to prevent RPC blocking (testing threshold)
        peer-limit-global = 200; # Max peers total (default 200)
        peer-limit-per-torrent = 50; # Max peers per torrent (default 50)
        download-queue-size = 5; # Only 1 concurrent download
        seed-queue-size = 1; # Only 1 concurrent seed
        download-queue-enabled = true;
        seed-queue-enabled = true;

        # Disable all peer discovery - trackers only
        dht-enabled = true;
        lpd-enabled = true;
        pex-enabled = true;
        scrape-paused-torrents-enabled = false;
        port-forwarding-enabled = false;

        # Limit speeds to reduce connection churn
        speed-limit-up = 100; # 100 KB/s upload limit
        speed-limit-up-enabled = true;
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
}
