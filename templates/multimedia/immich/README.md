# Immich

Photo/video backup, single-container deployment (`immich-server` serves both the API and the
web UI on port `2283`), `immich-machine-learning`, and `redis`. Uses the shared `postgresql`
stack (see `.env.example`), not a dedicated database container.

## First-time setup: "maintenance mode" (Immich v2.x)

On first boot (or after a major version upgrade), `immich-server` starts in **maintenance
mode**. In this mode only a handful of routes are mapped (`/api/server/*`,
`/api/admin/maintenance/*`, `/api/admin/database-backups`) — the old `/api/auth/admin-sign-up`
flow from Immich v1.x does **not** exist anymore and returns a plain 404 if you try the old
"open the web UI and sign up" approach.

To complete setup, check the `immich_server` container logs for a one-time login URL:

```bash
docker logs immich_server --tail 100 | grep -A2 "maintenance mode"
```

```
🚧 Immich is in maintenance mode, you can log in using the following URL:
https://my.immich.app/maintenance?token=<token>
```

Open that URL from a browser on the LAN (it must be able to reach `immich.home` /
`photo.home`). The token is a single-use admin credential — don't share it.

You can confirm whether the server is still in maintenance mode without authenticating:

```bash
curl -s http://192.168.1.2:2283/api/server/config
# {"maintenanceMode":true}  -> still in maintenance mode
```

## Don't use the built-in "restore from backup" against the shared Postgres instance

Immich's maintenance-mode restore (`select_database_restore` / `restore_database`) is built for
the official single-tenant deployment, where Immich owns its own dedicated Postgres container.
It does **not** work against this repo's shared `postgresql` instance:

- The backup is a `pg_dump --clean` style dump that includes `DROP ROLE postgres` /
  `CREATE ROLE postgres` statements, which fail (harmlessly) since the shared instance already
  has its own `postgres` superuser.
- More seriously, the restore script's `\connect` step appears to **change the live `postgres`
  role's password** to whatever was embedded in the old dump before failing on a mismatched
  password — even though the restore itself never completes. This breaks Postgres auth for
  every consumer of the shared instance, not just Immich.
- After that, the `immich` database itself was found dropped, leaving `immich-server` unable to
  start at all (`PostgresError: database "immich" does not exist`).

If this happens, recovery is two `psql` commands on the TNAS (local socket auth on the
`postgresql` container bypasses the broken password):

```bash
DOCKER=/var/subvols/8vEbTxkKvwa/@/@apps/DockerEngine/dockerd/bin/docker
$DOCKER exec postgresql psql -U postgres -c "ALTER ROLE postgres WITH PASSWORD 'changeme';"
$DOCKER exec postgresql psql -U postgres -c "CREATE DATABASE immich;"
```

(`changeme` must match `DB_PASSWORD` in `.env` / `POSTGRES_PASSWORD` in
`templates/database/postgresql/.env`.) Then recreate `immich_server` so it reconnects with a
working password. This resets Immich to a **fresh install** (`isInitialized:false`) — you'll go
through the normal first-admin sign-up again.

The original media files (uploads, thumbnails, the old `.sql.gz` backups) are untouched on disk
— only the database/library index is lost. To recover photos from before the reset, use
Immich's "scan library" / external library feature to re-index the orphaned files in the
`upload` volume rather than trying the built-in restore again.

If you ever need a real point-in-time restore on this setup, do it manually: load the dump into
a throwaway database on the same Postgres instance with `pg_restore --no-owner --no-privileges
--dbname=<temp>`, inspect/extract what you need, rather than letting Immich's restore feature
touch roles on the shared instance.

## Removed env vars

`IMMICH_SERVER_URL`, `IMMICH_WEB_URL`, `IMMICH_EXTERNAL_DOMAIN` were leftovers from the old
split-container Immich deployment (separate web/server/proxy containers) and are **not read**
by the current unified `immich-server` image — setting them has no effect. The public URL used
for share links is now configured after setup, in the web UI under **Administration > Settings
> Server Settings > External Domain**.

## External access (LAN + internet)

Same pattern as Home Assistant — see
[`homeassistant/docs/accesso-esterno-dns-companion.md`](../../../../homeassistant/docs/accesso-esterno-dns-companion.md)
for the full rationale (Dynu DDNS, Cloudflare CNAME override of the `*.clabnet.com` wildcard,
NPM, AdGuard split-DNS). Applied here as:

| Layer | Config |
|---|---|
| LAN domains | `immich.home`, `photo.home` → NPM → `immich_server:2283` |
| Internet domain | `photo.clabnet.com` → NPM → `immich_server:2283` |
| Cloudflare DNS | `photo` CNAME → `clabnet-ha.freeddns.org` (DNS only / grey cloud — overrides the `*.clabnet.com` wildcard that otherwise points at the Hetzner VPS) |
| TLS certificate | Reused the existing `*.clabnet.com` wildcard Let's Encrypt cert in NPM (no new cert needed) |
| NPM proxy host (`photo.clabnet.com`) | SSL forced ON, websockets ON, block common exploits ON |
| AdGuard DNS rewrite | `photo.clabnet.com → 192.168.1.2` (Filters > DNS rewrites) — avoids router hairpin NAT when on the home LAN/Wi-Fi |

### Verification

```bash
# Public DNS should resolve through the Dynu CNAME, not the Hetzner wildcard
nslookup photo.clabnet.com 8.8.8.8

# Local DNS (AdGuard) should resolve directly to the TNAS, no hairpin
nslookup photo.clabnet.com 192.168.1.2

# End-to-end HTTPS through NPM
curl -s -o /dev/null -w "%{http_code}\n" https://photo.clabnet.com/api/server/ping
```
