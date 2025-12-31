{pkgs, ...}: {
  networking.computerName = "dylbook";
  networking.hostName = "dylbook";
  networking.localHostName = "dylbook";

  system.primaryUser = "dylan";

  system.defaults = {
    NSGlobalDomain.ApplePressAndHoldEnabled = false;
    NSGlobalDomain.InitialKeyRepeat = 20;
    NSGlobalDomain.KeyRepeat = 2;
    dock = {
      show-recents = false;
      wvous-tl-corner = 2; # mission control hot corner
    };
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      CreateDesktop = true;
      ShowPathbar = true;
      ShowStatusBar = true;
    };
    menuExtraClock.Show24Hour = true;
    menuExtraClock.ShowSeconds = true;
  };

  users.knownUsers = ["dylan"];
  users.users.dylan = {
    uid = 501;
    name = "dylan";
    home = "/Users/dylan";
    createHome = true;
    shell = pkgs.zsh;
  };

  # System packages
  environment.systemPackages = with pkgs; [
    neovim
    git
  ];

  # Homebrew for GUI applications
  homebrew = {
    enable = true;
    brews = [
      "dagger"
    ];
    casks = [
      "firefox"
      "google-chrome"
      "transmission"
      "slack"
      "discord"
      "insomnia"
      "zed"
      "jetbrains-toolbox"
      "orbstack"
      "ghostty"
      "tailscale-app"
    ];
    caskArgs = {
      appdir = "~/Applications";
    };
  };

  # Fonts
  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.jetbrains-mono
  ];

  # Nix settings (using Determinate Nix)
  nix.enable = false;
  nix.settings.experimental-features = "nix-command flakes";

  # Shell
  programs.zsh.enable = true;

  # System state version
  system.stateVersion = 6;

  # Platform
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
}
