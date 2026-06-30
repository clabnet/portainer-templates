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
