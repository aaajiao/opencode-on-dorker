# server/ - Remote/Server Deployment

Server mode configuration for running OCD on remote machines or headless servers.

## Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Server mode container orchestration |
| `init.sh` | First-time server setup (creates dirs, builds image) |
| `status.sh` | Check server status and connectivity |
| `remote-setup.sh` | Tailscale/Cloudflare Tunnel configuration |
| `README.md` | Server deployment documentation |
| `REMOTE_ACCESS.md` | Remote access options guide |
| `tailscale.md` | Tailscale-specific setup |

## Server Mode vs Local Mode

| Aspect | Local (`ocd`) | Server (`docker-compose`) |
|--------|---------------|---------------------------|
| Startup | Interactive terminal | Background daemon |
| Restart | Manual | `unless-stopped` policy |
| Network | `--network host` | `network_mode: host` |
| Config | `~/.config/opencode/` | `./config/` (local to server dir) |
| Logs | Terminal | `docker-compose logs -f` |

## Quick Start

```bash
# 1. Copy .env from root
cp ../.env .env

# 2. Initialize server
./init.sh

# 3. Start server
docker-compose up -d

# 4. View logs
docker-compose logs -f

# 5. Stop server
docker-compose down
```

## docker-compose.yml Key Settings

```yaml
services:
  opencode:
    network_mode: host          # Required for OAuth callbacks
    restart: unless-stopped     # Auto-restart on failure
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:${PORT}/health"]
      interval: 30s
      timeout: 10s
```

## Remote Access Options

### 1. Tailscale (Recommended)
- Zero-config VPN
- Automatic HTTPS via Tailscale Serve
- Setup: `./remote-setup.sh --tailscale`

### 2. Cloudflare Tunnel
- Public HTTPS without port forwarding
- Requires Cloudflare account
- Setup: `./remote-setup.sh --cloudflare`

### 3. Direct IP
- Requires port forwarding
- Use with caution (no encryption)

## init.sh Workflow

1. Creates directory structure:
   ```
   server/
   ├── config/      # Server-specific config
   ├── data/        # Persistent data
   ├── state/       # Runtime state
   └── cache/       # Ephemeral cache
   ```

2. Generates config from templates (uses `../versions.lock`)

3. Builds Docker image via docker-compose

4. Displays next steps

## Differences from Local Config

| Aspect | Local | Server |
|--------|-------|--------|
| Config path | `~/.config/opencode/` | `./config/` |
| Data path | `~/.local/share/opencode/` | `./data/` |
| State path | `~/.local/state/opencode/` | `./state/` |
| Workspace | Auto-detected | `~/projects` (configurable) |

## Troubleshooting

**Container won't start**:
```bash
docker-compose logs --tail=50
```

**OAuth callback fails**:
- Ensure `network_mode: host` is set
- Check firewall allows the port

**Health check failing**:
```bash
curl -f http://localhost:${PORT}/health
```

**Reset server config**:
```bash
docker-compose down
rm -rf config/ data/ state/
./init.sh
```
