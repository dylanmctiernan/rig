{
  config,
  pkgs,
  lib,
  ...
}:
let
  commonConfig = import ../../../../common-config.nix;
  mimir = commonConfig.lgtm.mimir;
in
{
  # Note: NixOS Mimir module does not have a configurable dataDir option
  # It's hardcoded to /var/lib/mimir via systemd StateDirectory
  # All paths below must use /var/lib/mimir as the base

  # Ensure mimir starts after network is fully online to avoid boot race conditions
  systemd.services.mimir = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  services.mimir = {
    enable = true;

    extraFlags = [
      "-memberlist.bind-addr=127.0.0.1"
      "-memberlist.advertise-addr=127.0.0.1"
    ];

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
          retention_period = "8760h"; # 1 year
        };
      };

      compactor = {
        data_dir = "/var/lib/mimir/compactor";
        compaction_interval = "30m";
        deletion_delay = "2h";
      };

      memberlist = {
        abort_if_cluster_join_fails = false;
        bind_port = mimir.memberlistPort;
        join_members = [ ];
      };

      distributor = {
        ring = {
          instance_addr = "127.0.0.1";
          instance_interface_names = [ "lo" ]; # Use loopback for single-node
          kvstore = {
            store = "inmemory";
          };
        };
      };

      ingester = {
        ring = {
          instance_addr = "127.0.0.1";
          instance_interface_names = [ "lo" ]; # Use loopback for single-node
          kvstore = {
            store = "inmemory";
          };
          replication_factor = 1;
        };
      };

      store_gateway = {
        sharding_ring = {
          instance_addr = "127.0.0.1";
          replication_factor = 1;
          kvstore = {
            store = "inmemory";
          };
        };
      };

      ruler = {
        rule_path = "/var/lib/mimir/rules";
        ring = {
          instance_addr = "127.0.0.1";
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

      query_scheduler = {
        ring = {
          instance_addr = "127.0.0.1";
          kvstore = {
            store = "inmemory";
          };
        };
      };

      frontend = {
        scheduler_address = "127.0.0.1:${toString mimir.grpcPort}";
        address = "127.0.0.1";
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
}
