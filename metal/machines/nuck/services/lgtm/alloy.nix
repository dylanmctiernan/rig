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

      // Relabel journal logs to extract systemd unit as service label
      loki.relabel "journal" {
        forward_to = [loki.write.local.receiver]

        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label  = "unit"
        }
        rule {
          source_labels = ["__journal__hostname"]
          target_label  = "hostname"
        }
        rule {
          source_labels = ["__journal_priority"]
          target_label  = "level"
        }
      }

      // Loki logs receiver - receive logs from applications
      loki.source.journal "system_logs" {
        format_as_json = true
        max_age        = "12h"
        labels         = {
          job = "systemd-journal",
        }
        forward_to = [loki.relabel.journal.receiver]
      }

      // Loki write endpoint
      loki.write "local" {
        endpoint {
          url = "http://127.0.0.1:${toString loki.httpPort}/loki/api/v1/push"
        }
      }

      // OTLP receiver for traces, logs, and metrics
      otelcol.receiver.otlp "default" {
        grpc {
          endpoint = "127.0.0.1:${toString alloy.otlpGrpcPort}"
        }

        http {
          endpoint = "127.0.0.1:${toString alloy.otlpHttpPort}"
        }

        output {
          traces  = [otelcol.exporter.otlp.tempo.input]
          logs    = [otelcol.exporter.loki.local.input]
          metrics = [otelcol.processor.batch.default.input]
        }
      }

      // Batch processor for metrics (best practice for performance)
      otelcol.processor.batch "default" {
        output {
          metrics = [otelcol.exporter.prometheus.mimir.input]
        }
      }

      // Convert OTLP metrics to Prometheus format
      otelcol.exporter.prometheus "mimir" {
        forward_to = [prometheus.remote_write.mimir.receiver]
      }

      // OTLP exporter to Tempo for traces
      otelcol.exporter.otlp "tempo" {
        client {
          endpoint = "127.0.0.1:${toString tempo.grpcPort}"
          tls {
            insecure = true
          }
        }
      }

      // OTLP to Loki exporter for logs
      otelcol.exporter.loki "local" {
        forward_to = [loki.write.local.receiver]
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

      // Forgejo metrics
      prometheus.scrape "forgejo" {
        targets = [{
          __address__ = "127.0.0.1:${toString commonConfig.services.forgejo.httpPort}",
        }]
        metrics_path = "/metrics"
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

  # Add Alloy to systemd-journal group for journal access
  systemd.services.alloy.serviceConfig.SupplementaryGroups = [ "systemd-journal" ];
}
