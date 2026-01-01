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
      "nuck/authelia/session_secret" = {
        owner = "authelia-main";
        path = "/var/lib/authelia-main/secrets/session";
      };
      "nuck/authelia/oidc_hmac_secret" = {
        owner = "authelia-main";
        path = "/var/lib/authelia-main/secrets/oidc-hmac";
      };
      "nuck/authelia/forgejo_client_secret" = {
        owner = "authelia-main";
        path = "/var/lib/authelia-main/secrets/forgejo-client";
      };
      "nuck/authelia/oidc_rsa_private_key" = {
        owner = "authelia-main";
        path = "/var/lib/authelia-main/secrets/oidc-rsa-key.pem";
        mode = "0600";
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
  };

  virtualisation.docker.enable = true;

  nixpkgs.config.allowUnfree = true;

  nixpkgs.hostPlatform = "x86_64-linux";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
