# Homepage Dashboard Configuration

Homepage is a self-hosted dashboard that displays widgets for all your services.

## Quick Start

1. Set up environment variables (copy and customize to the NAS config location):

   ```bash
   cp .env.example /Volume1/public/config/homepage/.env
   # Edit .env with your actual service URLs and API keys
   ```

2. Redeploy the homepage service:
   ```bash
   docker compose -f templates/infrastructure/docker-compose.infrastructure.yml up -d homepage
   ```

## Available Widgets

### Infrastructure

- **Portainer** - Container management interface
- **AdGuard Home** - DNS filtering and ad blocking
- **Nginx Proxy Manager** - Reverse proxy and SSL management

### Monitoring

- **Uptime Kuma** - Uptime and availability monitoring
- **Speed Test** - Network speed test results
- **Tugtainer** - Docker image update monitoring (replaces deprecated WUD)

### Multimedia

- **Immich** - Self-hosted photo library
- **Jellyfin** - Media server (optional, commented out)

### Home Automation

- **Home Assistant** - Smart home automation platform

### Other

- **Dozzle** - Real-time Docker container logs

## Configuration Files

### services.yaml

Main configuration file that defines all dashboard widgets and sections.

**Structure:**

```yaml
- Section Name:
    - Service Name:
        description: Brief description
        icon: icon-name.png # From https://github.com/walkxcode/dashboard-icons
        href: http://service-url # Direct link to service
        container: container_name # For status indicator
        widget:
          type: widget_type # portainer, adguard, npm, etc.
          url: widget_url # Often same as href
          # Additional widget-specific options
```

### Environment Variables

All URLs and sensitive data use environment variable placeholders: `{{HOMEPAGE_VAR_NAME}}`

Copy `.env.example` to `.env` and customize with your actual values:

```bash
HOMEPAGE_VAR_PORTAINER_URL=http://192.168.1.2:9000
HOMEPAGE_VAR_ADGUARD_URL=http://192.168.1.2:8090
HOMEPAGE_VAR_TUGTAINER_URL=http://192.168.1.2:9412
# ... etc
```

## Tugtainer Integration

Tugtainer replaces the deprecated "What's Up Docker" (WUD) service for monitoring Docker image updates.

**Configuration:**

```yaml
- Monitoring:
    - Tugtainer:
        description: Docker image update monitor
        icon: docker.png
        href: "{{HOMEPAGE_VAR_TUGTAINER_URL}}"
        container: tugtainer
        widget:
          type: iframe
          url: "{{HOMEPAGE_VAR_TUGTAINER_URL}}"
```

**Setup:**

1. Ensure tugtainer service is running: `docker ps | grep tugtainer`
2. Set `HOMEPAGE_VAR_TUGTAINER_URL` in `.env` (e.g., `http://192.168.1.2:9412`)
3. Reload homepage to see the widget

## Adding New Widgets

1. Find the service icon at https://github.com/walkxcode/dashboard-icons
2. Add the widget configuration to `services.yaml` in the appropriate section
3. Add environment variables to `.env.example`
4. Check https://gethomepage.dev/latest/configs/services for widget-specific options

## Documentation

- **Homepage Docs**: https://gethomepage.dev/
- **Widget Reference**: https://gethomepage.dev/latest/configs/services
- **Icon Pack**: https://github.com/walkxcode/dashboard-icons
- **Project Reference**: https://github.com/solarorange/ansible-homelab

## Port & Access

- **Port**: 3005 (configurable via `HOMEPAGE_HTTP_PORT`)
- **URL**: http://localhost:3005 or http://[hostname]:3005
- **Default Access**: No authentication required (configure in services.yaml)

## Troubleshooting

**Widgets not loading:**

- Check environment variables are set correctly in `.env`
- Verify services are accessible from the homepage container
- Check container logs: `docker logs homepage`

**Icons not showing:**

- Ensure icon filename matches exactly (case-sensitive)
- Icons should be in `/app/config/icons/` or use URL from walkxcode/dashboard-icons

**Service unavailable:**

- Verify service is running: `docker ps`
- Check network connectivity: `docker exec homepage ping service-name`
- Verify URL in environment variables
