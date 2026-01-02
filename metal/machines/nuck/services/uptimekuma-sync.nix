{
  config,
  pkgs,
  lib,
  ...
}: let
  commonConfig = import ../../../common-config.nix;
  domain = commonConfig.network.domain;
  uptimeKuma = commonConfig.services.uptimeKuma;
  monitoring = commonConfig.monitoring;

  # Convert Nix monitor config to JSON for Python script
  monitorsJson = builtins.toJSON monitoring;

  # Python script to sync monitors
  syncScript = pkgs.writeScript "uptime-kuma-sync" ''
    #!${pkgs.python3.withPackages (ps: [ ps.uptime-kuma-api ])}/bin/python3
    import json
    import sys
    import os
    from uptime_kuma_api import UptimeKumaApi, MonitorType

    # Read monitor configuration
    config = json.loads('''${monitorsJson}''')

    # Uptime Kuma connection details
    UPTIME_KUMA_URL = "http://127.0.0.1:${toString uptimeKuma.httpPort}"

    # Get credentials from environment (set by systemd service)
    USERNAME = os.environ.get("UPTIME_KUMA_USERNAME")
    PASSWORD = os.environ.get("UPTIME_KUMA_PASSWORD")

    if not USERNAME or not PASSWORD:
        print("ERROR: UPTIME_KUMA_USERNAME and UPTIME_KUMA_PASSWORD must be set")
        sys.exit(1)

    def sync_monitors():
        """Sync monitor configuration to Uptime Kuma"""
        try:
            with UptimeKumaApi(UPTIME_KUMA_URL) as api:
                # Login
                try:
                    api.login(USERNAME, PASSWORD)
                    print("✓ Logged in to Uptime Kuma")
                except Exception as e:
                    print(f"✗ Login failed: {e}")
                    print("  Uptime Kuma may not be set up yet. Please complete initial setup first.")
                    sys.exit(0)  # Exit gracefully if not set up

                # Get existing monitors
                existing_monitors = api.get_monitors()
                existing_by_name = {m["name"]: m for m in existing_monitors}

                print(f"Found {len(existing_monitors)} existing monitors")

                # Process each group
                for group_key, group_data in config.get("groups", {}).items():
                    group_name = group_data.get("name", group_key)
                    monitors = group_data.get("monitors", [])

                    print(f"\nProcessing group: {group_name}")

                    for monitor_config in monitors:
                        name = monitor_config["name"]
                        mon_type = MonitorType.HTTP if monitor_config["type"] == "http" else MonitorType.HTTP
                        url = monitor_config["url"]
                        interval = monitor_config.get("interval", 60)
                        ignore_tls = monitor_config.get("ignoreTls", False)

                        # Check if monitor exists
                        if name in existing_by_name:
                            # Update existing monitor
                            monitor_id = existing_by_name[name]["id"]
                            try:
                                api.edit_monitor(
                                    monitor_id,
                                    type=mon_type,
                                    name=name,
                                    url=url,
                                    interval=interval,
                                    ignoreTls=ignore_tls
                                )
                                print(f"  ✓ Updated: {name}")
                            except Exception as e:
                                print(f"  ✗ Failed to update {name}: {e}")
                        else:
                            # Create new monitor
                            try:
                                api.add_monitor(
                                    type=mon_type,
                                    name=name,
                                    url=url,
                                    interval=interval,
                                    ignoreTls=ignore_tls
                                )
                                print(f"  ✓ Created: {name}")
                            except Exception as e:
                                print(f"  ✗ Failed to create {name}: {e}")

                print("\n✓ Monitor sync completed successfully")

        except Exception as e:
            print(f"✗ Error during sync: {e}")
            import traceback
            traceback.print_exc()
            sys.exit(1)

    if __name__ == "__main__":
        sync_monitors()
  '';
in {
  # Systemd service to sync Uptime Kuma monitors
  systemd.services.uptime-kuma-sync = {
    description = "Sync Uptime Kuma monitor configuration";
    after = ["uptime-kuma.service"];
    wants = ["uptime-kuma.service"];

    # Run this service manually or via timer
    wantedBy = [];

    serviceConfig = {
      Type = "oneshot";
      User = "uptime-kuma";
      Group = "uptime-kuma";

      # Credentials loaded from secrets
      # Add to secrets.yaml under nuck/uptime-kuma:
      #   username: your-uptime-kuma-username
      #   password: your-uptime-kuma-password
      # Then configure SOPS secret in sops.nix
      EnvironmentFile = lib.mkIf (config.sops.secrets ? "nuck/uptime-kuma/credentials")
        config.sops.secrets."nuck/uptime-kuma/credentials".path;

      ExecStart = "${syncScript}";

      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
    };
  };

  # Optional: Timer to run sync periodically (commented out by default)
  # systemd.timers.uptime-kuma-sync = {
  #   description = "Sync Uptime Kuma monitors periodically";
  #   wantedBy = ["timers.target"];
  #   timerConfig = {
  #     OnBootSec = "5min";
  #     OnUnitActiveSec = "1h";
  #   };
  # };
}
