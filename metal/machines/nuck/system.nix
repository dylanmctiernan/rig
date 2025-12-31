# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  ...
}: {
  # Sops secrets configuration
  # sops = {
  #   defaultSopsFile = ./secrets.yaml;
  #   age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

  #   secrets = {
  #     tailscale_auth_key = {};
  #   };
  # };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nuck";

  time.timeZone = "America/Toronto";

  i18n.defaultLocale = "en_US.UTF-8";

  console.keyMap = "dvorak-programmer";

  # Users
  users.users.dylan = {
    isNormalUser = true;
    extraGroups = ["wheel" "docker"];
  };

  # Allow passwordless sudo for wheel group (needed for Colmena deployments)
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

  # Firewall configuration
  networking.firewall = {
    enable = true;
    trustedInterfaces = ["tailscale0"];
    allowedUDPPorts = [config.services.tailscale.port];
  };

  services.tailscale = {
    enable = true;
  };

  virtualisation.docker.enable = true;

  # Nix configuration
  nixpkgs.config.allowUnfree = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
