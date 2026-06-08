# Plan: Add Individual Service Templates to templates.json

## Goal

Add `type: 1` (individual container) entries to templates.json for services that can run independently, enabling single-service deployment without the entire stack.

## Target Services (Standalone - no internal dependencies)

| Service             | Image                                        | Ports                                           | Volumes              | Env Vars                                        | Category             |
| ------------------- | -------------------------------------------- | ----------------------------------------------- | -------------------- | ----------------------------------------------- | -------------------- |
| AdGuard Home        | adguard/adguardhome:latest                   | 53:53/tcp, 53:53/udp, 80:80, 443:443, 3000:3000 | work, conf           | TZ, ADGUARD_HTTP/HTTPS/SETUP_PORT               | Networking/DNS       |
| Nginx Proxy Manager | jc21/nginx-proxy-manager:latest              | 80:80, 443:443, 81:81                           | data, letsencrypt    | TZ, NPM_HTTP/HTTPS/ADMIN_PORT, NPM_DISABLE_IPV6 | Proxy                |
| PostgreSQL          | postgres:16-alpine                           | 5432:5432                                       | data                 | POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB   | Database             |
| Dozzle              | amir20/dozzle:latest                         | 9999:8080                                       | -                    | TZ, DOZZLE_HTTP_PORT                            | Monitoring/Logs      |
| MySpeed             | germannewsmaker/myspeed:latest               | 5216:5216                                       | data                 | TZ, PUID, PGID                                  | Monitoring/Network   |
| Tugtainer           | ghcr.io/quenary/tugtainer:latest             | 9412:80                                         | -                    | TZ, TUGTAINER_HTTP_PORT                         | Monitoring           |
| Uptime Kuma         | louislam/uptime-kuma:2                       | 3001:3001                                       | data                 | TZ                                              | Monitoring/Uptime    |
| WUD                 | getwud/wud:latest                            | 3003:3000                                       | -                    | TZ                                              | Monitoring           |
| Plex                | lscr.io/linuxserver/plex:latest              | -                                               | config, tv, movies   | TZ, PUID, PGID, VERSION                         | Media                |
| Jellyfin            | jellyfin/jellyfin                            | 8096:8096                                       | config, cache, media | TZ                                              | Media                |
| Home Assistant      | home-assistant/home-assistant                | 8123:8123                                       | config               | TZ                                              | Home Automation      |
| Mosquitto           | eclipse-mosquitto                            | 1883:1883, 9001:9001                            | config, data, log    | TZ                                              | Home Automation/MQTT |
| Mailpit             | axllent/mailpit:latest                       | 8025:8025, 1025:1025                            | data                 | TZ                                              | Tools/Mail           |
| Dokploy             | dokploy/dokploy:latest                       | 3002:3000                                       | app                  | TZ                                              | Tools/DevOps         |
| Invoicerr           | ghcr.io/impre-visible/invoicerr:v1.3.0-debug | 8020:80                                         | -                    | DATABASE*URL, APP_URL, SMTP*\*, JWT_SECRET      | Tools/Webapp         |
| Homepage            | ghcr.io/gethomepage/homepage:latest          | 3005:3000                                       | config               | TZ, HOMEPAGE_HTTP_PORT                          | Tools/Dashboard      |

## Services NOT added (have internal dependencies)

- **Immich** (requires redis + database - already in multimedia stack)
- **InvoiceShelf App** (depends on mail service)

## Changes to templates.json

Add individual container entries (type: 1) after each stack entry. Each entry will include:

- `image`: Docker image reference
- `ports`: Array of host:container port mappings
- `volumes`: Array with container paths and bind mounts (using relative paths where applicable)
- `env`: Environment variables with defaults from .env.example files
- `restart_policy`: From compose files
- `categories`: Appropriate categorization
- `logo`: CB avatar (already updated)

## Files to modify

- `templates/templates.json` - Add ~15 individual container entries

## Verification

- JSON syntax validation after changes
