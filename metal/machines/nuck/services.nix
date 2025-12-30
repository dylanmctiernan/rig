{config, ...}: {
  services.grafana = {
    enable = true;
    settings.server = {
      http_addr = "0.0.0.0";
      http_port = 10000;
    };
  };

  services.prometheus = {
    enable = true;
    globalConfig.scrape_interval = "10s";
    port = 10010;
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = ["localhost:${toString config.services.prometheus.exporters.node.port}"];
          }
        ];
      }
    ];
  };

  services.prometheus.exporters.node = {
    enable = true;
    port = 10011;
    enabledCollectors = ["systemd" "processes"];
  };
}
