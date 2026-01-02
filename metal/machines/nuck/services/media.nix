{config, ...}: let
  commonConfig = import ../../../common-config.nix;
in {
  # Nixarr media server stack configuration
  # Documentation: https://nixarr.com/

  nixarr = {
    enable = true;

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

      # VPN configuration - disabled for now as requested
      vpn.enable = false;
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
  };

  # Only open Transmission peer port for BitTorrent
  networking.firewall.allowedTCPPorts = [
    commonConfig.services.transmission.peerPort
  ];
  networking.firewall.allowedUDPPorts = [
    commonConfig.services.transmission.peerPort
  ];
}
