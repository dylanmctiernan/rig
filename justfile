# Test/build local dylbook configuration without applying
dylbook-plan:
    darwin-rebuild build --flake .#dylbook

# Apply dylbook configuration from GitHub
dylbook-apply:
    sudo darwin-rebuild switch --flake github:dylanmctiernan/rig#dylbook

# Deploy to a specific host using Colmena over Tailscale
deploy host:
    colmena apply --on {{ host }}

# Deploy to all hosts using Colmena
deploy-all:
    colmena apply
