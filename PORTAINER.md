# Portainer Setup (TNAS host)

Portainer CE is the management UI for all stacks in this repo. It runs directly on the TNAS Docker host (not as a template — it's the tool that deploys the templates).

> Credentials and API keys are **not** stored in this file. Keep them in your password manager. See [TNAS Access](CLAUDE.md#tnas-access) in `CLAUDE.md` for SSH details.

---

## Prerequisites

```bash
# Shared bridge network used by every stack in this repo
docker network create --driver bridge horizon_network

# Persistent volume for Portainer's own data
docker volume create portainer_data
```

---

## Initial Install

```bash
docker run -d \
  --name portainer \
  --restart=always \
  --network horizon_network \
  -p 8000:8000 \
  -p 9443:9443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  -v /Volume1/public:/Volume1/public:ro \
  portainer/portainer-ce:sts
```

Open the console at **https://192.168.1.2:9443**, then use *Get Started* to set up a **Local Environment**.

### Why `/Volume1/public:/Volume1/public:ro` is required

Several templates (e.g. [templates/infrastructure/homepage/docker-compose.yml](templates/infrastructure/homepage/docker-compose.yml)) reference an `env_file:` by **absolute host path** (e.g. `/Volume1/public/config/homepage/.env`), because the `.env` lives in a separate repo on the NAS, not inside `portainer-templates/`.

Portainer's compose engine resolves `env_file:` paths from **its own container's filesystem**, not the TNAS host filesystem. Without this bind mount, any stack referencing an absolute `/Volume1/public/...` path fails to deploy with:

```
failed to resolve services environment: env file /Volume1/public/... not found
```

Mounting `/Volume1/public` read-only into the Portainer container gives its compose engine visibility into that path without granting it write access to the share.

---

## Upgrade Portainer

1. **Backup first**: Portainer UI → *Settings* → *General* → *Backup configuration* → *Download*.
2. SSH into the TNAS (see [TNAS Access](CLAUDE.md#tnas-access)) and run:

   ```bash
   DOCKER=/var/subvols/8vEbTxkKvwa/@/@apps/DockerEngine/dockerd/bin/docker

   $DOCKER stop portainer
   $DOCKER rename portainer portainer_old   # keep as rollback instead of removing outright
   $DOCKER pull portainer/portainer-ce:sts

   $DOCKER run -d \
     --name portainer \
     --restart=always \
     --network horizon_network \
     -p 8000:8000 \
     -p 9443:9443 \
     -v /var/run/docker.sock:/var/run/docker.sock \
     -v portainer_data:/data \
     -v /Volume1/public:/Volume1/public:ro \
     portainer/portainer-ce:sts
   ```

3. Verify the new container is healthy and the UI loads, then remove the old one:

   ```bash
   $DOCKER rm portainer_old
   ```

> The `:sts` (Short-Term Support) tag tracks the latest stable releases. `:latest` was used for the original install; `:sts` is the convention going forward.

---

## App Templates URL

Register this repo's template feed in Portainer under **Settings → App Templates**:

```
http://<nas-ip>:8099/templates.json
```

(Requires the template server to be running — see [README.md](README.md#template-server).)

---

## API Access

Portainer's REST API is used for scripted operations. Generate a key under **My Account → Access Tokens**, and store it in your password manager — never commit it to this repo.
