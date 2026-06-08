# Portainer Templates facts
# Updated: 2026-06-08

## Network

- Single external bridge: `horizon_network`
- Declared in `templates/_shared/networks.yml`

## Templates server

- nginx on port 8099
- serves `templates/templates.json`
- container_name: `portainer-templates`

## Category aggregators

- database, home_automation, infrastructure, monitoring, multimedia, tools, webapp

## Stacks (type: 3)

- Infrastructure
- Database
- Monitoring
- Multimedia
- Home Automation
- Tools
- Web applications

## Individual services (type: 1)

- Wendy backend, AdGuard, Nginx Proxy Manager, PostgreSQL, Dozzle, MySpeed, Tugtainer, Uptime Kuma, WUD, Plex, Jellyfin, Home Assistant, Mosquitto, Dokploy, Invoicerr, Homepage
