# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  ...
}:
let
  vars =
    let
      c = import ../../../config;
    in
    c { self = c; };
in
{

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Core OS settings
  networking.hostName = vars.machines.nuck.hostName;
  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "dvorak-programmer";

  # Users
  users.users.dylan = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = [
      vars.people.dylan.ssh.publicKey
    ];
  };

  # Enable passwordless sudo for wheel group
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
    neovim
    procs
    bottom
    xh
    fd
  ];

  # mDNS for .local resolution
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

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
    # SSH is allowed via services.openssh.openFirewall
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
