# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**portainer-templates** is a collection of Docker Compose templates for a self-hosted homelab, organized by category and served as [Portainer App Templates](https://docs.portainer.io/user/docker/templates) via a local nginx container. It includes stack templates (multi-service category deployments) and individual container templates for standalone deployment.

## Architecture

```
portainer-templates/
├── docker-compose.yml          ← template server (nginx, port 8099)
├── Dockerfile                  ← nginx:alpine serving templates/ as static files
├── Format-YmlFiles.ps1         ← YAML normalizer (CRLF/whitespace/indentation)
└── templates/
    ├── templates.json          ← Portainer App Templates definition (stacks + individual containers)
    ├── _shared/networks.yml    ← horizon_network, single source of truth
    └── <category>/
        ├── docker-compose.<category>.yml   ← aggregator, includes per-service files
        └── <service>/docker-compose.yml
```

Each category (`database`, `home_automation`, `infrastructure`, `monitoring`, `multimedia`, `tools`, `webapp`) has an aggregator compose file that `include:`s the individual service files plus `../_shared/networks.yml`. The aggregator is the deployment entry point for that category. All services share the external `horizon_network` bridge network.

A service can be present in a category but **disabled**: its `include:` line is commented out in the aggregator rather than deleted (e.g. jellyfin, dokploy, invoicerr, cateringcare, wud as of this writing — check the aggregator file for current state).

See [README.md](README.md) for the full live directory tree and per-category service/port tables, and [templates/NETWORK_DIAGRAM.md](templates/NETWORK_DIAGRAM.md) for network topology and data-flow diagrams.

## Common Commands

```bash
# One-time prerequisite
docker network create horizon_network

# Run the template server
docker compose up -d --build
curl http://localhost:8099/templates.json   # verify

# Deploy a category stack
docker compose -f templates/<category>/docker-compose.<category>.yml up -d
```

```powershell
# Format YAML (prettier — JSON/MD/YAML)
npm run format

# Format YAML (CRLF→LF, trailing whitespace, trailing newline; also halves
# nginxpm's indentation from 4-space to 2-space as a one-off normalization)
.\Format-YmlFiles.ps1 -WhatIf   # dry run
.\Format-YmlFiles.ps1           # apply
```

To enable a disabled service: uncomment its `include:` line in the category's aggregator file, then redeploy that category stack.

## templates/templates.json Conventions

Each service template entry (`type: 1` = individual container, `type: 3` = stack) includes:

- `type`: 1 for individual container, 3 for a multi-service stack
- `image`: Docker image with tag
- `registry`: Only for non-Docker Hub (ghcr.io, lscr.io)
- `ports`: Array of "host:container" or "host:container/proto"
- `volumes`: Named volumes (just `container`) or bind mounts (`container` + `bind`)
- `env`: Environment variables with defaults
- `categories`: For Portainer UI filtering
- `logo`: CB avatar (consistent across all)
- `network`: `"horizon_network"` for services joining it; omit for standalone (e.g., Dokploy)

## Docker Compose Service Conventions

From `templates/infrastructure/README.md`, applied across the repo:

- **Key order** in service definitions: `image`, `container_name`, `hostname`, `restart`, `networks`, `ports`, `volumes`, `environment`, `labels`.
- **Healthchecks**: 30s interval, 10s timeout, 3 retries, 30-40s start period, where applicable.

## Naming Conventions

- **Service names** (`name` field in templates.json): lowercase, no underscores (e.g., `adguard`, `nginxpm`, `uptimekuma`)
- **File paths**: relative paths from repo root
- **Volumes**: bind mounts use `/Volume1/public/config/{service}/...` NAS paths for consistency

## Cross-Repo Docs

Home Assistant external access (LAN discovery, TLS Companion, Cloudflare DDNS, NPM, Tunnel) is documented outside this repo: `../homeassistant/docs/accesso-esterno-dns-companion.md` (on TNAS: `/Volume1/public/config/homeassistant/docs/`).

## TNAS Access

| Detail                     | Value                                                                    |
| -------------------------- | ------------------------------------------------------------------------ |
| IP                         | 192.168.1.2                                                              |
| SSH port                   | 9222                                                                     |
| SSH user                   | clabnet                                                                  |
| SSH key                    | `~/.ssh/tnas_homelab` (on Windows: `$env:USERPROFILE\.ssh\tnas_homelab`) |
| Docker binary              | `/var/subvols/8vEbTxkKvwa/@/@apps/DockerEngine/dockerd/bin/docker`       |
| Docker is NOT in PATH      | Always use full binary path                                              |
| portainer-templates on NAS | `/Volume1/public/config/portainer-templates/`                            |
| homepage config on NAS     | `/Volume1/public/config/homepage/`                                       |

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

## Adding New Services

1. Create the compose file at `templates/{category}/{service}/docker-compose.yml`, following the key-order and healthcheck conventions above.
2. Add an `include:` line for it in `templates/{category}/docker-compose.{category}.yml`.
3. Add a `.env.example` if the service needs configuration.
4. Add a `type: 1` entry to `templates/templates.json` following existing patterns.
5. Run `npm run format` and/or `.\Format-YmlFiles.ps1` before committing.
