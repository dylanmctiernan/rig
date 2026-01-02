# Agent Guide for Maclab Infrastructure

## Overview

**Maclab** is a declarative NixOS homelab infrastructure using Nix flakes, managing both servers (NixOS) and development machines (nix-darwin).

**Core Technologies**: NixOS, Colmena (deployment), nix-darwin, home-manager, sops-nix (secrets)

## Repository Structure

```
├── flake.nix              # Nix flake entry point
├── justfile               # Deployment commands
├── secrets.yaml           # Encrypted secrets (sops)
├── metal/
│   ├── common-config.nix  # SINGLE SOURCE OF TRUTH: ports, domains, paths
│   └── machines/
│       ├── nuck/          # NixOS server
│       │   └── services/
│       │       ├── caddy.nix        # Reverse proxy + internal TLS
│       │       ├── authelia.nix     # SSO
│       │       ├── forgejo.nix      # Git
│       │       ├── backrest.nix     # Backup UI
│       │       ├── uptimekuma.nix   # Monitoring
│       │       └── lgtm/            # Observability stack
│       │           ├── loki.nix     # Logs
│       │           ├── grafana.nix  # Dashboards
│       │           ├── tempo.nix    # Traces
│       │           ├── mimir.nix    # Metrics
│       │           └── alloy.nix    # Collector
│       └── dylbook/       # macOS dev machine
```

## Architecture

### Port Scheme (5000-5599)
All ports defined in `common-config.nix`:
- **5000-5099**: Application services (Forgejo, Uptime Kuma, Backrest)
- **5100-5199**: Infrastructure (Authelia)
- **5200-5299**: Observability HTTP (Loki, Grafana, Tempo, Mimir, Alloy)
- **5300-5399**: Observability gRPC
- **5400-5499**: OTLP receivers
- **5500-5599**: Internal clustering

### Service Pattern
Every service follows this:
1. Listen on `127.0.0.1:PORT` (localhost only)
2. Caddy reverse proxy at `subdomain.mac.lab`
3. Internal TLS via Caddy's local CA
4. Optional Authelia SSO
5. Metrics scraped by Alloy → Mimir
6. Logs collected by Alloy → Loki

### LGTM Stack
- **Loki** (5200): Log aggregation, 1yr retention
- **Grafana** (5201): Dashboards at `grafana.mac.lab`
- **Tempo** (5202): Traces, OTLP on 5400/5401, 1yr retention
- **Mimir** (5203): Metrics storage, 1yr retention
- **Alloy** (5204): Collects everything, OTLP on 5402/5403

## Development Workflow

**CRITICAL**: Colmena deploys from GitHub, not local files.

```bash
# 1. Read before modifying
cat metal/machines/nuck/services/lgtm/alloy.nix

# 2. Make focused change (preserve exact formatting)
# Edit file...

# 3. Commit + push (required before deploy!)
git add .
git commit -m "description"
git push

# 4. Deploy from GitHub
just nuck-apply  # Pulls from GitHub, builds on target

# 5. Verify
ssh dylan@nuck.mac.lab 'systemctl status alloy.service'
ssh dylan@nuck.mac.lab 'journalctl -u alloy.service --since "1 minute ago"'

# 6. Debug if needed
ssh dylan@nuck.mac.lab 'journalctl -u alloy.service -f'

# 7. Iterate
```

### Deployment Commands

```bash
just nuck-plan      # Show what would change
just nuck-apply     # Deploy to nuck server
just dylbook-apply  # Deploy to macOS machine
```

## Common Tasks

### Add New Service

1. **Define in `common-config.nix`**:
   ```nix
   services.newservice = {
     httpPort = 5003;  # Next available in range
     subdomain = "newservice";
     stateDir = "/var/lib/newservice";
   };
   ```

2. **Create `services/newservice.nix`**:
   ```nix
   let commonConfig = import ../../../common-config.nix; in {
     # Use commonConfig.services.newservice.httpPort
     # Listen on 127.0.0.1:PORT only
   }
   ```

3. **Add Caddy vhost** in `caddy.nix`:
   ```nix
   "${commonConfig.services.newservice.subdomain}.${domain}" = {
     extraConfig = ''
       tls internal
       reverse_proxy localhost:${toString commonConfig.services.newservice.httpPort}
     '';
   };
   ```

4. **Import in `services/default.nix`**

5. **Add Alloy scraper** (if metrics available)

6. **Deploy**: Commit → Push → `just nuck-apply` → Verify

### Debug Service

```bash
# Status
ssh dylan@nuck.mac.lab 'systemctl status {service}'

# Logs
ssh dylan@nuck.mac.lab 'journalctl -u {service} --since "5 minutes ago"'

# Test endpoint
ssh dylan@nuck.mac.lab 'curl http://localhost:{port}'
curl -k https://{subdomain}.mac.lab
```

### Edit Secrets

```bash
sops secrets.yaml  # Encrypted with age

# Reference in config:
sops.secrets.service-password.sopsFile = ../../../secrets.yaml;
# Available at: config.sops.secrets.service-password.path
```

## Key Principles

1. **Always read files before modifying** - Never propose changes to unread code
2. **Commit + push before deploying** - Colmena deploys from GitHub
3. **One service at a time** - Update and verify incrementally
4. **Use `common-config.nix`** - All ports/domains/paths centralized
5. **Preserve exact formatting** - Nix is whitespace-sensitive
6. **Follow the port scheme** - Use next available in correct range
7. **Verify with logs** - Check `journalctl` after every deployment
8. **Small commits** - Easier to debug and rollback

## Agent Best Practices

### DO
✅ Start by reading `common-config.nix`  
✅ Use `just` commands for deployment  
✅ Verify service status + logs after changes  
✅ Follow existing service patterns as templates  
✅ Document why in comments, not what  
✅ Test incrementally (one service at a time)  

### DON'T
❌ Propose changes to files you haven't read  
❌ Deploy without committing + pushing  
❌ Hardcode values that belong in `common-config.nix`  
❌ Break the port scheme (5000-5599 ranges)  
❌ Make multiple unrelated changes in one commit  
❌ Skip log verification after deployment  

## Known Issues

- **Node exporter systemd collector disabled**: D-Bus access conflicts with systemd hardening. Processes collector enabled instead.
- **Journal unit labels unavailable**: `loki.source.journal` doesn't expose systemd unit names as relabelable labels.

## Troubleshooting

**Service fails to start**: Check `journalctl -u {service}`  
**Can't access `subdomain.mac.lab`**: Check Caddy status, DNS, service listening on port  
**Metrics missing in Grafana**: Verify Alloy scrape config has correct port  
**Colmena fails**: Ensure changes committed + pushed to GitHub  

---

**Maintained by**: Dylan McTiernan (dylan@mctiernan.io)  
**Domain**: mac.lab  
**Deployment**: Git → GitHub → Colmena → Target machine
