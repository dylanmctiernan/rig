# Test/build local dylbook configuration without applying
dylbook-plan:
    darwin-rebuild build --flake .#dylbook

# Apply dylbook configuration from GitHub
dylbook-apply:
    sudo darwin-rebuild switch --flake github:dylanmctiernan/rig#dylbook

# Plan nuck configuration (show what would change without applying)
nuck-plan:
    colmena build --on nuck --impure

# Apply nuck configuration (deploy changes)
nuck-apply:
    colmena apply --on nuck
