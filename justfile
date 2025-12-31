# Rig - Maclab Infrastructure Management

# Default recipe
default:
    @just --list

# Backport config files from running apps to repo (for apps that don't support symlinks)
backport: backport-zed

# Backport Zed settings to repo (Zed overwrites symlinks, so we copy back)
backport-zed:
    cp -L ~/.config/zed/settings.json metal/machines/dylbook/files/zed/settings.json
    @echo "Backported Zed settings to repo"

# Show diff between running configs and repo
diff:
    @echo "=== Zed ==="
    @diff -u metal/machines/dylbook/files/zed/settings.json ~/.config/zed/settings.json 2>/dev/null || true
    @echo ""
    @echo "=== Ghostty ==="
    @diff -u metal/machines/dylbook/files/ghostty/config ~/.config/ghostty/config 2>/dev/null || true
    @echo ""
    @echo "=== Neovim ==="
    @diff -u metal/machines/dylbook/files/neovim/init.vim ~/.config/nvim/init.vim 2>/dev/null || true

# Build and apply darwin configuration from local flake
darwin-switch:
    sudo darwin-rebuild switch --flake .#dylbook

# Build and apply darwin configuration from remote
darwin-switch-remote:
    sudo darwin-rebuild switch --flake github:dylanmctiernan/rig#dylbook

# Build darwin configuration without switching
darwin-build:
    darwin-rebuild build --flake .#dylbook

# Build and apply nuck configuration via SSH
nuck-switch:
    ssh root@nuck "nixos-rebuild switch --flake github:dylanmctiernan/rig#nuck"

# Commit and push changes
push message:
    git add -A && git commit -m "{{message}}" && git push
