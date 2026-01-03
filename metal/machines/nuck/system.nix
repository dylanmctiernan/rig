# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  ...
}: let
  commonConfig = import ../../common-config.nix;
in {
  # Sops secrets configuration
  sops = {
    defaultSopsFile = ../../../secrets.yaml;
    # Use age keys instead of SSH host keys
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets = {
      # Authelia secrets
      "nuck/authelia/jwt_secret" = {
        owner = "authelia-main";
        path = "/var/lib/authelia-main/secrets/jwt";
      };
      "nuck/authelia/storage_encryption_key" = {
        owner = "authelia-main";
        path = "/var/lib/authelia-main/secrets/storage-encryption-key";
      };
      "nuck/authelia/oidc_hmac_secret" = {
        owner = "authelia-main";
        path = "/var/lib/authelia-main/secrets/oidc-hmac";
      };
      "nuck/authelia/forgejo_oidc_client_secret" = {
        owner = "authelia-main";
        group = "forgejo";
        mode = "0440";
        path = "/var/lib/authelia-main/secrets/forgejo-oidc-client-secret";
      };
      "nuck/authelia/grafana_oidc_client_secret" = {
        owner = "authelia-main";
        group = "grafana";
        mode = "0440";
        path = "/var/lib/authelia-main/secrets/grafana-oidc-client-secret";
      };

      "nuck/authelia/oidc_rsa_private_key" = {
        owner = "authelia-main";
        path = "/var/lib/authelia-main/secrets/oidc-rsa-key.pem";
        mode = "0600";
      };

      # Tailscale persistent auth key (single-use, consumed at first bootstrap)
      "nuck/tailscale/auth_key" = {
        owner = "root";
        # default path will be /run/secrets/..., sufficient for tailscale module
      };
    };
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = commonConfig.machines.nuck.hostname;

  time.timeZone = "America/Toronto";

  i18n.defaultLocale = "en_US.UTF-8";

  console.keyMap = "dvorak-programmer";

  # Users
  users.users.dylan = {
    isNormalUser = true;
    extraGroups = ["wheel" "docker"];
    openssh.authorizedKeys.keys = [
      commonConfig.dylan.sshPublicKey
    ];
  };

  # Enable passwordless sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    neovim
    procs
    bottom
    xh
    fd
  ];

  # SSH configuration (LAN only - not exposed to internet)
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
    openFirewall = true;
  };

  # Firewall configuration
  networking.firewall = {
    enable = true;
    trustedInterfaces = ["tailscale0"];
    allowedUDPPorts = [config.services.tailscale.port];
    # SSH is allowed via services.openssh.openFirewall
  };

  services.tailscale = {
    enable = true;
    # Use the persistent auth-key provisioned by sops; consumed once, then ignored
    authKeyFile = config.sops.secrets."nuck/tailscale/auth_key".path;

    # Advertise this machine as a DNS server for the tailnet
    # Accept DNS queries from other tailscale devices
    extraUpFlags = [
      "--advertise-tags=tag:dns"
      "--accept-dns=false"  # Don't use tailscale's DNS, use our own CoreDNS
    ];
  };

  virtualisation.docker.enable = true;

  nixpkgs.config.allowUnfree = true;

  nixpkgs.hostPlatform = "x86_64-linux";

  # Trust Caddy's internal CA for local HTTPS
  security.pki.certificateFiles = [
    "/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt"
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
