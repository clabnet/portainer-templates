# Portainer App Templates

Docker Compose stacks for a self-hosted homelab, organized by category and served as [Portainer App Templates](https://docs.portainer.io/user/docker/templates) via a local nginx container.

---

## Architecture

```
portainer-templates/
├── docker-compose.yml              ← template server (nginx, port 8099)
├── Dockerfile
├── nginx.conf
├── .env                            ← credentials & app config
├── Format-YmlFiles.ps1             ← YAML formatter (CRLF/whitespace)
└── templates/
    ├── _shared/
    │   └── networks.yml            ← horizon_network (single source of truth)
    ├── database/
    │   ├── docker-compose.database.yml
    │   └── postgresql/
    ├── home_automation/
    │   ├── docker-compose.home_automation.yml
    │   ├── homeassistant/
    │   └── mosquitto/
    ├── infrastructure/
    │   ├── docker-compose.infrastructure.yml
    │   ├── adguard/
    │   ├── homepage/
    │   └── nginxpm/
    ├── monitoring/
    │   ├── docker-compose.monitoring.yml
    │   ├── dozzle/
    │   ├── myspeed/
    │   ├── tugtainer/
    │   ├── uptime/
    │   └── wud/                        ← deprecated
    ├── multimedia/
    │   ├── docker-compose.multimedia.yml
    │   ├── immich/
    │   ├── jellyfin/               ← disabled
    │   └── plex/
    ├── tools/
    │   ├── docker-compose.tools.yml
    │   ├── dokploy/                ← disabled
    │   ├── invoicerr/              ← disabled
    │   └── invoiceshelf/
    └── webapp/
        ├── docker-compose.yml
        ├── cateringcare/           ← disabled
        └── wendy/
```

Each category has an **aggregator** compose file (`docker-compose.<category>.yml`) that `include:`s the individual service files. The aggregator is the entry point when deploying a category stack.

All containers share the external `horizon_network` bridge network, declared once in `templates/_shared/networks.yml` and included by every aggregator.

---

## Network Architecture

See [NETWORK_DIAGRAM.md](NETWORK_DIAGRAM.md) for a comprehensive visualization of the homelab network, including:
- Service topology and connections
- Data flow patterns
- Port assignments
- Security layers
- Scaling considerations

---

## Prerequisites

- Docker Engine with Compose v2
- The `horizon_network` external network must exist before any stack is deployed

```bash
docker network create horizon_network
```

---

## Template Server

The root `docker-compose.yml` runs an nginx container that serves `templates/` as static files.

```bash
# Build and start
docker compose up -d --build

# Verify
curl http://localhost:8099/templates.json
```

Register the URL in Portainer under **Settings → App Templates**:

```
http://<nas-ip>:8099/templates.json
```

---

## Services

### Database

| Service    | Port | Description      |
|------------|------|------------------|
| PostgreSQL | 5432 | Relational database, shared by other stacks |

```bash
docker compose -f templates/database/docker-compose.database.yml up -d
```

### Home Automation

| Service       | Port | Description              |
|---------------|------|--------------------------|
| Home Assistant | 8123 | Home automation platform |
| Mosquitto     | 1883 | MQTT broker              |

```bash
docker compose -f templates/home_automation/docker-compose.home_automation.yml up -d
```

### Infrastructure

| Service             | Port      | Description                  |
|---------------------|-----------|------------------------------|
| AdGuard Home        | 8090      | DNS filtering & ad blocking  |
| Homepage            | 3005      | Homelab dashboard            |
| Nginx Proxy Manager | 80/443/81 | Reverse proxy + SSL (admin: 81) |

```bash
docker compose -f templates/infrastructure/docker-compose.infrastructure.yml up -d
```

### Monitoring

| Service    | Port | Description                        |
|------------|------|------------------------------------|
| UptimeKuma | 3001 | Uptime & availability monitoring   |
| MySpeed    | 8080 | Scheduled internet speed tests     |
| Dozzle     | 9999 | Real-time Docker log viewer        |
| Tugtainer  | 9412 | Docker image update monitor        |

```bash
docker compose -f templates/monitoring/docker-compose.monitoring.yml up -d
```

**Note:** Tugtainer replaces the deprecated WUD service for monitoring Docker image updates.

### Multimedia

| Service | Port | Description              |
|---------|------|--------------------------|
| Immich  | 2283 | Self-hosted photo library |
| Plex    | 32400 | Media server            |

```bash
docker compose -f templates/multimedia/docker-compose.multimedia.yml up -d
```

### Tools

| Service      | Port | Description                          |
|--------------|------|--------------------------------------|
| InvoiceShelf | 8090 | Invoicing & quote management (+ Mailpit on 8025) |

```bash
docker compose -f templates/tools/docker-compose.tools.yml up -d
```

### Web Apps

| Service | Ports       | Description            |
|---------|-------------|------------------------|
| Wendy   | 5454 / 3454 | Wedding events manager (backend / frontend) |

```bash
docker compose -f templates/webapp/docker-compose.yml up -d
```

---

## Configuration

Copy `.env.example` files before first use:

```bash
cp templates/webapp/wendy/.env.example templates/webapp/wendy/.env
cp templates/webapp/cateringcare/.env.example templates/webapp/cateringcare/.env
```

The root `.env` holds shared credentials (PostgreSQL, JWT secrets, Permit.io API key). Do not commit real values — the file is gitignored.

Port defaults are set via environment variables in each service file (e.g. `${HOMEPAGE_HTTP_PORT:-3005}`). Override by setting the variable in the relevant `.env`.

---

## Enabling Disabled Services

Services marked *disabled* above have their `include:` line commented out in the aggregator. To enable one:

1. Uncomment the line in the aggregator file, e.g.:
   ```yaml
   # templates/multimedia/docker-compose.multimedia.yml
   include:
     - ../_shared/networks.yml
     - ./immich/docker-compose.yml
     - ./jellyfin/docker-compose.yml   # ← uncomment
   ```
2. Redeploy the category stack.

---

## YAML Formatting

All `.yml` files are normalized with `Format-YmlFiles.ps1` (LF line endings, no trailing whitespace, 2-space indentation). Run it after editing files on Windows:

```powershell
# Dry run
.\Format-YmlFiles.ps1 -WhatIf

# Apply
.\Format-YmlFiles.ps1
```

---

## Homepage Dashboard

The **Homepage** service provides a centralized dashboard for accessing all homelab services.

### Setup

1. Copy example configuration to NAS:
   ```bash
   cp templates/infrastructure/homepage/.env.example /Volume1/public/config/homepage/.env
   cp templates/infrastructure/homepage/services.example.yaml /Volume1/public/config/homepage/config/services.yaml
   ```

2. Customize `.env` with your service URLs and API keys

3. Configure widgets in `services.yaml` (see [Homepage Configuration Guide](templates/infrastructure/homepage/README.md))

### Available Widgets

- **Infrastructure**: Portainer, AdGuard Home, Nginx Proxy Manager
- **Monitoring**: Uptime Kuma, MySpeed, Dozzle, **Tugtainer** (Docker updates)
- **Multimedia**: Immich, Jellyfin (optional)
- **Home Automation**: Home Assistant
- **Other**: Custom links and services

See [Homepage README](templates/infrastructure/homepage/README.md) for detailed configuration and widget options.
