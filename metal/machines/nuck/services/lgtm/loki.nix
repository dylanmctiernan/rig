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

      # Run in single-binary mode (all components in one process)
      target = "all";

      server = {
        http_listen_port = loki.httpPort;
        grpc_listen_port = loki.grpcPort;
        http_listen_address = "127.0.0.1";
        grpc_listen_address = "127.0.0.1";
      };

      common = {
        instance_addr = "127.0.0.1";
        ring = {
          instance_addr = "127.0.0.1";
          kvstore = {
            store = "inmemory";
          };
        };
        replication_factor = 1;
        path_prefix = loki.stateDir;
      };

      # Disable query scheduler and query frontend in single-binary mode
      query_scheduler = {
        max_outstanding_requests_per_tenant = 100;
      };

      frontend = {
        scheduler_address = "";
      };

      querier = {
        max_concurrent = 4;
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
          active_index_directory = "${loki.stateDir}/tsdb-index";
          cache_location = "${loki.stateDir}/tsdb-cache";
        };
        filesystem = {
          directory = "${loki.stateDir}/chunks";
        };
      };

      compactor = {
        working_directory = "${loki.stateDir}/compactor";
        compaction_interval = "10m";
        retention_enabled = true;
        retention_delete_delay = "2h";
        retention_delete_worker_count = 150;
        delete_request_store = "filesystem";
      };

      limits_config = {
        retention_period = "8760h"; # 1 year
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
        ingestion_rate_mb = 4;
        ingestion_burst_size_mb = 6;
      };

      ruler = {
        storage = {
          type = "local";
          local = {
            directory = "${loki.stateDir}/rules";
          };
        };
        rule_path = "${loki.stateDir}/rules-temp";
        ring = {
          kvstore = {
            store = "inmemory";
          };
        };
      };
    };
  };

  # Note: The NixOS Loki module automatically creates the stateDir via systemd StateDirectory
  # Subdirectories (chunks, tsdb-index, rules, etc.) are created by Loki on first run
}
