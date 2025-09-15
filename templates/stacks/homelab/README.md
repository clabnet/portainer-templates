# Homelab Docker Compose Stack

A complete homelab setup with optimized Docker Compose configuration including:
- AdGuard Home (DNS filtering)
- Dozzle (Log viewer)
- Immich (Photo management)
- Nginx Proxy Manager (Reverse proxy)
- Homepage (Dashboard)

## Quick Start

1. Customize variables in `.env` file (already provided)
2. Deploy the stack: `docker-compose -f docker-compose.homelab.yml --env-file .env up -d`

## Configuration

### Environment Variables

Key variables to customize in `.env`:

```bash
# Network Configuration
MACVLAN_INTERFACE=eth1                    # Your network interface
MACVLAN_SUBNET=192.168.1.0/24            # Your subnet
MACVLAN_IP_RANGE=192.168.1.0/29          # IP range for containers

# Security
DB_PASSWORD=your_secure_password_here      # Change this!

# Paths
HOMEPAGE_CONFIG_DIR=./homepage/config      # Homepage config directory
```

### Network Architecture

- **Default Network**: Bridge network for inter-service communication
- **MACVLAN Network**: Direct network access for services that need it (AdGuard, Homepage)

### Services

| Service | Port | Purpose |
|---------|------|---------|
| AdGuard Home | 8090 | DNS filtering & DHCP |
| Dozzle | 9999 | Container log viewer |
| Homepage | 3015 | Dashboard |
| Nginx PM | 81 | Proxy manager admin |
| Immich | 2283 | Photo management |

### Volumes

All volumes use named volumes with consistent naming:
- `adguard_work` / `adguard_conf`
- `immich_uploads` / `immich_database` / etc.
- `nginxpm_data` / `nginxpm_letsencrypt`

## Health Monitoring

All services include standardized healthchecks with:
- 30s intervals
- 10s timeout
- 3 retries
- 30-40s start period

## Security Features

- Read-only Docker socket mounts
- Minimal container privileges
- Secure network isolation
- Environment-based configuration