# Rig - Maclab Infrastructure Management

# Default recipe
default:
    @just --list

# Sync config files from running apps to repo
sync-configs: sync-zed sync-ghostty sync-neovim

# Sync Zed settings from running config to repo
sync-zed:
    cp ~/.config/zed/settings.json metal/machines/dylbook/files/zed/settings.json
    @echo "Synced Zed settings"

# Sync Ghostty config from running config to repo
sync-ghostty:
    cp ~/.config/ghostty/config metal/machines/dylbook/files/ghostty/config
    @echo "Synced Ghostty config"

# Sync Neovim config from running config to repo
sync-neovim:
    cp ~/.config/nvim/init.vim metal/machines/dylbook/files/neovim/init.vim
    @echo "Synced Neovim config"

# Apply config files from repo to running apps
apply-configs: apply-zed apply-ghostty apply-neovim

# Apply Zed settings from repo to running config
apply-zed:
    cp metal/machines/dylbook/files/zed/settings.json ~/.config/zed/settings.json
    @echo "Applied Zed settings"

# Apply Ghostty config from repo to running config
apply-ghostty:
    cp metal/machines/dylbook/files/ghostty/config ~/.config/ghostty/config
    @echo "Applied Ghostty config"

# Apply Neovim config from repo to running config
apply-neovim:
    cp metal/machines/dylbook/files/neovim/init.vim ~/.config/nvim/init.vim
    @echo "Applied Neovim config"

# Build and apply darwin configuration
darwin-switch:
    sudo darwin-rebuild switch --flake github:dylanmctiernan/rig#dylbook

# Build darwin configuration without switching
darwin-build:
    darwin-rebuild build --flake github:dylanmctiernan/rig#dylbook

# Build and apply nuck configuration via SSH
nuck-switch:
    ssh root@nuck "nixos-rebuild switch --flake github:dylanmctiernan/rig#nuck"

# Show diff of local configs vs repo
diff-configs:
    @echo "=== Zed ==="
    @diff -u metal/machines/dylbook/files/zed/settings.json ~/.config/zed/settings.json || true
    @echo ""
    @echo "=== Ghostty ==="
    @diff -u metal/machines/dylbook/files/ghostty/config ~/.config/ghostty/config || true
    @echo ""
    @echo "=== Neovim ==="
    @diff -u metal/machines/dylbook/files/neovim/init.vim ~/.config/nvim/init.vim || true
