# Claude Code Context for portainer-templates

## Project Overview

**portainer-templates** is a collection of Docker Compose templates and individual service definitions for a homelab deployment platform using Portainer. The project includes stack templates (multi-service deployments) and individual container templates for standalone service deployment.

### Key Files

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
