# Infrastructure Services

A complete infrastructure setup with optimized Docker Compose configuration including:

- **AdGuard Home** - DNS filtering & ad blocking
- **Homepage** - Centralized dashboard for all services
- **Nginx Proxy Manager** - Reverse proxy with SSL/TLS management

## Quick Start

1. Copy example environment file:

   ```bash
   cp .env.example .env
   ```

2. Customize variables in `.env` with your service URLs and credentials

3. Deploy the infrastructure stack:

   ```bash
   docker compose -f docker-compose.infrastructure.yml up -d
   ```

4. Set up Homepage dashboard:
   - See [Homepage Configuration](homepage/README.md) for detailed setup

## Configuration

### Environment Variables

All services are configured via environment variables in `.env`. Key variables:

```bash
# Port Configuration
HOMEPAGE_HTTP_PORT=3005              # Homepage dashboard port
ADGUARD_HTTP_PORT=8090               # AdGuard HTTP port
ADGUARD_HTTPS_PORT=8443              # AdGuard HTTPS port
NPM_HTTP_PORT=80                      # Nginx Proxy Manager HTTP
NPM_HTTPS_PORT=443                    # Nginx Proxy Manager HTTPS
NPM_ADMIN_PORT=81                     # Nginx Proxy Manager admin panel

# Service URLs (for Homepage dashboard widgets)
HOMEPAGE_VAR_PORTAINER_URL=http://192.168.1.2:9000
HOMEPAGE_VAR_ADGUARD_URL=http://192.168.1.2:8090
HOMEPAGE_VAR_NPM_URL=http://192.168.1.2:81
# ... see .env.example for complete list
```

Copy `.env.example` and customize with your actual values.

### Homepage Dashboard Configuration

The Homepage service requires additional configuration files on the NAS:

- **Config location**: `/Volume1/public/config/homepage/`
- **Files needed**:
  - `.env` - Environment variables for Homepage widgets
  - `config/services.yaml` - Dashboard widget definitions

See [Homepage README](homepage/README.md) for complete setup instructions.

### Network Architecture

- **horizon_network**: External bridge network for inter-service communication
- All services connect to this network (defined in `../_shared/networks.yml`)

### Services

| Service             | Port      | Purpose                        |
| ------------------- | --------- | ------------------------------ |
| AdGuard Home        | 8090      | DNS filtering & ad blocking    |
| Homepage            | 3005      | Centralized dashboard          |
| Nginx Proxy Manager | 80/443/81 | Reverse proxy + SSL management |

### Volumes

All services use named volumes for persistent data:

- `adguard_work` - AdGuard working directory
- `adguard_conf` - AdGuard configuration

## Service Configuration

### Consistent Key Ordering

All Docker Compose service definitions follow a standardized key order:

1. **image** - Container image
2. **container_name** - Container name
3. **hostname** - Internal hostname
4. **restart** - Restart policy
5. **networks** - Networks to connect to
6. **ports** - Port mappings
7. **volumes** - Volume mounts
8. **environment** - Environment variables
9. **labels** - Container labels

This improves readability and reduces diffs during maintenance.

### Health Monitoring

All services include standardized healthchecks with:

- 30s check intervals
- 10s timeout
- 3 retries
- 30-40s start period

### Security Features

- Read-only Docker socket mounts
- Minimal container privileges
- Secure network isolation (horizon_network)
- Environment-based configuration (no hardcoded credentials)
