{
  config,
  pkgs,
  lib,
  ...
}: let
  commonConfig = import ../../../../common-config.nix;
  tempo = commonConfig.lgtm.tempo;
in {
  # Note: NixOS Tempo module does not have a configurable dataDir option
  # It's hardcoded to /var/lib/tempo via systemd StateDirectory
  # All paths below must use /var/lib/tempo as the base

  services.tempo = {
    enable = true;

    settings = {
      server = {
        http_listen_address = "127.0.0.1";
        http_listen_port = tempo.httpPort;
        grpc_listen_address = "127.0.0.1";
        grpc_listen_port = tempo.grpcPort;
      };

      distributor = {
        receivers = {
          otlp = {
            protocols = {
              http = {
                endpoint = "127.0.0.1:${toString tempo.otlpHttpPort}";
              };
              grpc = {
                endpoint = "127.0.0.1:${toString tempo.otlpGrpcPort}";
              };
            };
          };
        };
      };

      ingester = {
        max_block_duration = "5m";
      };

      compactor = {
        compaction = {
          block_retention = "8760h"; # 1 year
        };
      };

      metrics_generator = {
        registry = {
          external_labels = {
            source = "tempo";
          };
        };
        storage = {
          path = "/var/lib/tempo/generator/wal";
          remote_write = [
            {
              url = "http://127.0.0.1:${toString commonConfig.lgtm.mimir.httpPort}/api/v1/push";
              send_exemplars = true;
            }
          ];
        };
      };

      storage = {
        trace = {
          backend = "local";
          wal = {
            path = "/var/lib/tempo/wal";
          };
          local = {
            path = "/var/lib/tempo/blocks";
          };
        };
      };

      overrides = {
        defaults = {
          metrics_generator = {
            processors = ["service-graphs" "span-metrics" "local-blocks"];
          };
        };
      };
    };
  };
}
