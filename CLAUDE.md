# Claude Code Context for portainer-templates

## Project Overview

**portainer-templates** is a collection of Docker Compose templates and individual service definitions for a homelab deployment platform using Portainer. The project includes stack templates (multi-service deployments) and individual container templates for standalone service deployment.

### Key Files

- **homeassistant/docs/accesso-esterno-dns-companion.md** — Runbook HA: discovery LAN, TLS Companion, Cloudflare DDNS, NPM, Tunnel (repo: `../homeassistant/docs/`, TNAS: `/Volume1/public/config/homeassistant/docs/`)
- **templates/templates.json** — Portainer UI template definitions (8 stack templates + 16 individual container templates as of e58c4f8)
- **templates/** — Docker Compose files organized by category (infrastructure, database, monitoring, multimedia, home_automation, tools, webapp)
- **stack files** — `docker-compose.*.yml` files that aggregate services via `include:` directives

### Recent Work

- Added 15 new individual service templates (type:1) for standalone deployment (commit e58c4f8)
- Services include: AdGuard Home, Nginx Proxy Manager, PostgreSQL, Dozzle, Uptime Kuma, Home Assistant, Mosquitto, Plex, Jellyfin, Dokploy, Invoicerr, Homepage, and others

## Knowledge Graph

A graphify knowledge graph exists at `graphify-out/graph.json`. The graph includes:
- Service definitions and their relationships
- Docker Compose structure and shared patterns
- Portainer template schema and configuration

To explore the graph:
- View interactive HTML: `graphify-out/graph.html` (open in browser)
- Read audit report: `graphify-out/GRAPH_REPORT.md`
- Query the graph: `/graphify query "<your question>"`
- Update on commits: the post-commit hook auto-rebuilds on changes

## TNAS Access

| Detail | Value |
|--------|-------|
| IP | 192.168.1.2 |
| SSH port | 9222 |
| SSH user | clabnet |
| SSH key | `~/.ssh/tnas_homelab` (on Windows: `$env:USERPROFILE\.ssh\tnas_homelab`) |
| Docker binary | `/var/subvols/8vEbTxkKvwa/@/@apps/DockerEngine/dockerd/bin/docker` |
| Docker is NOT in PATH | Always use full binary path |
| portainer-templates on NAS | `/Volume1/public/config/portainer-templates/` |
| homepage config on NAS | `/Volume1/public/config/homepage/` |

### Deploy / recreate a stack on TNAS

```bash
DOCKER=/var/subvols/8vEbTxkKvwa/@/@apps/DockerEngine/dockerd/bin/docker
cd /Volume1/public/config/portainer-templates
$DOCKER compose -f templates/<category>/docker-compose.<category>.yml up -d
```

### PowerShell SSH helper (from Windows)

```powershell
$docker = '/var/subvols/8vEbTxkKvwa/@/@apps/DockerEngine/dockerd/bin/docker'
ssh -p 9222 -i "$env:USERPROFILE\.ssh\tnas_homelab" clabnet@192.168.1.2 "$docker <command>"
```

> **Note**: Use PowerShell variable interpolation (`$docker = '...'`) — do NOT escape `$` in the SSH string or use `export` inside the remote command, as both cause the command to hang or fail.

## Conventions

### JSON Templates (templates/templates.json)

Each service template entry (type:1) includes:
- `type`: 1 for individual container
- `image`: Docker image with tag
- `registry`: Only for non-Docker Hub (ghcr.io, lscr.io)
- `ports`: Array of "host:container" or "host:container/proto"
- `volumes`: Named volumes (just `container`) or bind mounts (`container` + `bind`)
- `env`: Environment variables with defaults
- `categories`: For Portainer UI filtering
- `logo`: CB avatar (consistent across all)
- `network`: "horizon_network" for services joining it; omit for standalone (e.g., Dokploy)

### Naming

- **Service names (name field)**: lowercase, no underscores (e.g., `adguard`, `nginxpm`, `uptimekuma`)
- **File paths**: use relative paths from repo root
- **Volumes**: bind mounts use `/Volume1/public/config/{service}/...` NAS paths for consistency

## Adding New Services

1. Create compose file in appropriate `templates/{category}/{service}/docker-compose.yml`
2. Add type:1 entry to `templates/templates.json` following existing patterns
3. Include all required fields: image, ports, volumes, env, categories, restart_policy
4. Commit — the post-commit hook will rebuild the knowledge graph automatically
5. Query the graph if you need to understand relationships: `/graphify query "How does X integrate with Y?"`
