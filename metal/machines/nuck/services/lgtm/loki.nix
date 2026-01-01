{
  config,
  pkgs,
  lib,
  ...
}: let
  commonConfig = import ../../../../common-config.nix;
  loki = commonConfig.lgtm.loki;
in {
  services.loki = {
    enable = true;

    configuration = {
      auth_enabled = false;

      server = {
        http_listen_port = loki.httpPort;
        grpc_listen_port = loki.grpcPort;
        http_listen_address = "127.0.0.1";
        grpc_listen_address = "127.0.0.1";
      };

      common = {
        ring = {
          instance_addr = "127.0.0.1";
          kvstore = {
            store = "inmemory";
          };
        };
        replication_factor = 1;
        path_prefix = "/var/lib/loki";
      };

      schema_config = {
        configs = [{
          from = "2024-01-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }];
      };

      storage_config = {
        tsdb_shipper = {
          active_index_directory = "/var/lib/loki/tsdb-index";
          cache_location = "/var/lib/loki/tsdb-cache";
        };
        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };

      compactor = {
        working_directory = "/var/lib/loki/compactor";
        compaction_interval = "10m";
        retention_enabled = true;
        retention_delete_delay = "2h";
        retention_delete_worker_count = 150;
        delete_request_store = "filesystem";
      };

      limits_config = {
        retention_period = "744h"; # 31 days
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
        ingestion_rate_mb = 4;
        ingestion_burst_size_mb = 6;
      };

      ruler = {
        storage = {
          type = "local";
          local = {
            directory = "/var/lib/loki/rules";
          };
        };
        rule_path = "/var/lib/loki/rules-temp";
        ring = {
          kvstore = {
            store = "inmemory";
          };
        };
      };
    };
  };
}
