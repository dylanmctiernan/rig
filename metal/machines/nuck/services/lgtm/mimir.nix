{
  config,
  pkgs,
  lib,
  ...
}: let
  commonConfig = import ../../../../common-config.nix;
  mimir = commonConfig.lgtm.mimir;
in {
  services.mimir = {
    enable = true;

    configuration = {
      target = "all";

      multitenancy_enabled = false;

      server = {
        http_listen_address = "127.0.0.1";
        http_listen_port = mimir.httpPort;
        grpc_listen_address = "127.0.0.1";
        grpc_listen_port = mimir.grpcPort;
        log_level = "info";
      };

      common = {
        storage = {
          backend = "filesystem";
          filesystem = {
            dir = "/var/lib/mimir/data";
          };
        };
      };

      blocks_storage = {
        backend = "filesystem";
        filesystem = {
          dir = "/var/lib/mimir/blocks";
        };
        tsdb = {
          dir = "/var/lib/mimir/tsdb";
          retention_period = "744h"; # 31 days
        };
      };

      compactor = {
        data_dir = "/var/lib/mimir/compactor";
        compaction_interval = "30m";
        deletion_delay = "2h";
      };

      ingester = {
        ring = {
          instance_addr = "127.0.0.1";
          kvstore = {
            store = "inmemory";
          };
          replication_factor = 1;
        };
      };

      store_gateway = {
        sharding_ring = {
          replication_factor = 1;
          kvstore = {
            store = "inmemory";
          };
        };
      };

      ruler = {
        rule_path = "/var/lib/mimir/rules";
        ring = {
          kvstore = {
            store = "inmemory";
          };
        };
      };

      ruler_storage = {
        backend = "filesystem";
        filesystem = {
          dir = "/var/lib/mimir/ruler";
        };
      };

      alertmanager = {
        data_dir = "/var/lib/mimir/alertmanager";
        enable_api = true;
        external_url = "http://127.0.0.1:${toString mimir.httpPort}/alertmanager";
      };

      alertmanager_storage = {
        backend = "filesystem";
        filesystem = {
          dir = "/var/lib/mimir/alertmanager-storage";
        };
      };

      limits = {
        ingestion_rate = 10000;
        ingestion_burst_size = 20000;
        max_global_series_per_user = 150000;
        max_global_series_per_metric = 20000;
      };
    };
  };

  # Ensure Mimir directories exist
  systemd.tmpfiles.rules = [
    "d /var/lib/mimir 0750 mimir mimir -"
    "d /var/lib/mimir/data 0750 mimir mimir -"
    "d /var/lib/mimir/blocks 0750 mimir mimir -"
    "d /var/lib/mimir/tsdb 0750 mimir mimir -"
    "d /var/lib/mimir/compactor 0750 mimir mimir -"
    "d /var/lib/mimir/rules 0750 mimir mimir -"
    "d /var/lib/mimir/ruler 0750 mimir mimir -"
    "d /var/lib/mimir/alertmanager 0750 mimir mimir -"
    "d /var/lib/mimir/alertmanager-storage 0750 mimir mimir -"
  ];
}
