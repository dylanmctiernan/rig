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
      "firefox@developer-edition"
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

  # Trust Caddy CA certificate from nuck for mac.lab domains
  system.activationScripts.postActivation.text = ''
    echo "Installing Caddy CA certificate..."

    # Fetch the latest certificate from nuck
    CERT_PATH="/tmp/caddy-ca-latest.crt"
    if ${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=no root@nuck 'cat /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt' > "$CERT_PATH" 2>/dev/null; then
      # Check if certificate needs to be installed/updated
      if ! /usr/bin/security find-certificate -c "Caddy Local Authority" /Library/Keychains/System.keychain &>/dev/null; then
        /usr/bin/security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$CERT_PATH"
        echo "Caddy CA certificate installed successfully"
      else
        echo "Caddy CA certificate already installed"
      fi
      rm -f "$CERT_PATH"
    else
      echo "Warning: Could not fetch Caddy CA certificate from nuck (this is normal on first install)"
    fi
  '';

  # Nix settings (using Determinate Nix)
  nix.enable = false;
  nixpkgs.config.allowUnfree = true;

  # Shell
  programs.zsh.enable = true;

  # Platform
  nixpkgs.hostPlatform = "aarch64-darwin";

  # System state version
  system.stateVersion = 6;
}
