{
  config,
  pkgs,
  lib,
  ...
}: let
  commonConfig = import ../../../../common-config.nix;
  alloy = commonConfig.lgtm.alloy;
  loki = commonConfig.lgtm.loki;
  tempo = commonConfig.lgtm.tempo;
  mimir = commonConfig.lgtm.mimir;
in {
  services.alloy = {
    enable = true;

    extraFlags = [
      "--server.http.listen-addr=127.0.0.1:${toString alloy.httpPort}"
      "--storage.path=/var/lib/alloy"
    ];

    configPath = pkgs.writeText "alloy-config.alloy" ''
      // Logging configuration
      logging {
        level  = "info"
        format = "json"
      }

      // Loki logs receiver - receive logs from applications
      loki.source.journal "system_logs" {
        path          = "/var/log/journal"
        format_as_json = true
        forward_to    = [loki.write.local.receiver]
      }

      // Loki write endpoint
      loki.write "local" {
        endpoint {
          url = "http://127.0.0.1:${toString loki.httpPort}/loki/api/v1/push"
        }
      }

      // OTLP receiver for traces
      otelcol.receiver.otlp "default" {
        grpc {
          endpoint = "127.0.0.1:${toString tempo.otlpGrpcPort}"
        }

        http {
          endpoint = "127.0.0.1:${toString tempo.otlpHttpPort}"
        }

        output {
          traces  = [otelcol.exporter.otlp.tempo.input]
        }
      }

      // OTLP exporter to Tempo
      otelcol.exporter.otlp "tempo" {
        client {
          endpoint = "127.0.0.1:${toString tempo.grpcPort}"
          tls {
            insecure = true
          }
        }
      }

      // Prometheus scrape config for self-monitoring
      prometheus.scrape "alloy" {
        targets = [{
          __address__ = "127.0.0.1:${toString alloy.httpPort}",
        }]
        forward_to = [prometheus.remote_write.mimir.receiver]
      }

      // Loki metrics
      prometheus.scrape "loki" {
        targets = [{
          __address__ = "127.0.0.1:${toString loki.httpPort}",
        }]
        forward_to = [prometheus.remote_write.mimir.receiver]
      }

      // Tempo metrics
      prometheus.scrape "tempo" {
        targets = [{
          __address__ = "127.0.0.1:${toString tempo.httpPort}",
        }]
        forward_to = [prometheus.remote_write.mimir.receiver]
      }

      // Mimir metrics
      prometheus.scrape "mimir" {
        targets = [{
          __address__ = "127.0.0.1:${toString mimir.httpPort}",
        }]
        forward_to = [prometheus.remote_write.mimir.receiver]
      }

      // Grafana metrics
      prometheus.scrape "grafana" {
        targets = [{
          __address__ = "127.0.0.1:${toString commonConfig.lgtm.grafana.httpPort}",
        }]
        forward_to = [prometheus.remote_write.mimir.receiver]
      }

      // Node exporter for system metrics
      prometheus.exporter.unix "local" {
        // Default settings
      }

      prometheus.scrape "node" {
        targets    = prometheus.exporter.unix.local.targets
        forward_to = [prometheus.remote_write.mimir.receiver]
      }

      // Remote write to Mimir
      prometheus.remote_write "mimir" {
        endpoint {
          url = "http://127.0.0.1:${toString mimir.httpPort}/api/v1/push"
        }
      }
    '';
  };

  # Ensure Alloy storage directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/alloy 0750 alloy alloy -"
  ];
}
