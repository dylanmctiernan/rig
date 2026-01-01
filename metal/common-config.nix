# Shared configuration values for mac.lab infrastructure
# Non-sensitive values that are used across multiple machines
{
  # Dylan's personal information
  dylan = {
    name = "Dylan McTiernan";
    email = "dylan@mctiernan.io";
    sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE9aV63mII6UUHP9Shz6zMmGIlAd752I7LzgMTEshkYN dylan@mctiernan.io";
  };

  # Network configuration
  network = {
    domain = "mac.lab";
  };

  # Machine-specific configuration
  machines = {
    nuck = {
      tailscaleIp = "100.114.41.97";
      hostname = "nuck";
    };
  };
}
