{ config, ... }:

{
  sops = {
    # Default location for the age key on the machine
    age.keyFile = "/var/lib/sops-nix/key.txt";

    # This will generate a new key if one doesn't exist
    age.generateKey = true;

    # Default secrets file for this machine
    defaultSopsFile = ./secrets.yaml;

    # Secrets are decrypted to /run/secrets by default
    # Each secret below will be available at /run/secrets/<name>

    # Example secret definitions (uncomment and customize as needed):
    # secrets.example_password = {};
    # secrets.example_api_key = {
    #   # Custom path instead of /run/secrets/example_api_key
    #   path = "/run/keys/api-key";
    # };
    # secrets.service_env = {
    #   # Set owner/group for service access
    #   owner = "someservice";
    #   group = "someservice";
    # };
  };
}
