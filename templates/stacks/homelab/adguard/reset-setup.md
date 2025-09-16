# Reset AdGuard Setup Wizard

If the AdGuard setup wizard doesn't appear, follow these steps:

## Option 1: Reset Volumes (Recommended)
```bash
# Stop the container
docker-compose down

# Remove the configuration volume to reset setup
docker volume rm adguard_conf

# Restart the container
docker-compose up -d
```

## Option 2: Reset Configuration Files
```bash
# Stop the container
docker-compose down

# Clear configuration directory
docker run --rm -v adguard_conf:/data alpine sh -c "rm -rf /data/*"

# Restart the container
docker-compose up -d
```

## Access Setup Wizard
- URL: http://localhost:3000
- Or: http://YOUR_SERVER_IP:3000

## After Setup
The setup wizard will automatically redirect you to the main interface on the configured HTTP port (default 8090).