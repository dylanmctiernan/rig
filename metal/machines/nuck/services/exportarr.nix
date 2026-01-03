{
  config,
  pkgs,
  lib,
  ...
}:
let
  commonConfig = import ../../../common-config.nix;
  services = commonConfig.services;
  exportarr = services.exportarr;
in
{
  # Exportarr - Prometheus metrics exporters for *arr apps
  # Each app needs its own exporter instance

  services.prometheus.exporters = {
    # Sonarr exporter
    exportarr-sonarr = {
      enable = true;
      port = exportarr.sonarrPort;
      url = "http://127.0.0.1:${toString services.sonarr.httpPort}";
      apiKeyFile = config.sops.secrets."exportarr/sonarr_api_key".path;
    };

    # Radarr exporter
    exportarr-radarr = {
      enable = true;
      port = exportarr.radarrPort;
      url = "http://127.0.0.1:${toString services.radarr.httpPort}";
      apiKeyFile = config.sops.secrets."exportarr/radarr_api_key".path;
    };

    # Lidarr exporter
    exportarr-lidarr = {
      enable = true;
      port = exportarr.lidarrPort;
      url = "http://127.0.0.1:${toString services.lidarr.httpPort}";
      apiKeyFile = config.sops.secrets."exportarr/lidarr_api_key".path;
    };

    # Prowlarr exporter
    exportarr-prowlarr = {
      enable = true;
      port = exportarr.prowlarrPort;
      url = "http://127.0.0.1:${toString services.prowlarr.httpPort}";
      apiKeyFile = config.sops.secrets."exportarr/prowlarr_api_key".path;
      environment = {
        # Backfill historical data on startup
        PROWLARR__BACKFILL = "true";
      };
    };
  };

  # Secrets for API keys
  sops.secrets = {
    "exportarr/sonarr_api_key" = {
      sopsFile = ../../../secrets.yaml;
      owner = "exportarr-sonarr";
    };
    "exportarr/radarr_api_key" = {
      sopsFile = ../../../secrets.yaml;
      owner = "exportarr-radarr";
    };
    "exportarr/lidarr_api_key" = {
      sopsFile = ../../../secrets.yaml;
      owner = "exportarr-lidarr";
    };
    "exportarr/prowlarr_api_key" = {
      sopsFile = ../../../secrets.yaml;
      owner = "exportarr-prowlarr";
    };
  };
}
