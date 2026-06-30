# Mosquitto (MQTT Broker)

Eclipse Mosquitto MQTT broker, used by Home Assistant and other services on `horizon_network`.

## Ports

| Port | Purpose                |
| ---- | ----------------------- |
| 1883 | MQTT                     |
| 9001 | WebSocket (optional)     |

## Adding a user

```bash
DOCKER=/var/subvols/8vEbTxkKvwa/@/@apps/DockerEngine/dockerd/bin/docker
$DOCKER exec -it mqtt /bin/sh
mosquitto_passwd /mosquitto/config/passwd mqtt_user
```

This will print a warning:

```
Warning: File /mosquitto/config/passwd owner is not root. Future versions will refuse to load this file.
```

**Do not `chown root:root` it** — despite the warning text, this image (mosquitto 2.1.2) drops privileges to the `mosquitto` user (uid 1883, same as the owner of `mosquitto.conf`) *before* it opens the password file. A root-owned `0700` file is then unreadable by that uid and the broker fails to start (`password-file: Error: Unable to open pwfile`), crash-looping forever on `restart: unless-stopped` with no obvious symptom besides MQTT clients getting connection-refused. The bind mount comes from the NAS filesystem, so editing the file from a Windows/SMB client (e.g. via the network share) recreates it owned by your SMB user with restrictive Unix perms — that's what breaks it, not the "owner is not root" warning itself.

Fix the ownership to match `mosquitto.conf` instead:

```bash
$DOCKER exec -u root mqtt chown mosquitto:mosquitto /mosquitto/config/passwd
$DOCKER exec -u root mqtt chmod 0640 /mosquitto/config/passwd
$DOCKER restart mqtt
```

(Or directly on the NAS filesystem: `chown 1883:1883` + `chmod 0640` on `/Volume1/public/config/mosquitto/config/passwd`.)

Make sure `password_file /mosquitto/config/passwd` is set in `mosquitto.conf`, then test the new login with `mqtt_user` and the password you set.

### Troubleshooting: broker crash-looping, MQTT clients can't connect

`log_dest file` (the default in this setup) means `docker logs mqtt` shows almost nothing useful — startup/persistence-restore lines appear, but the actual fatal error does not, because it's written only to `/mosquitto/log/mosquitto.log` on the NAS, not to stdout. To see the real error, run mosquitto in the foreground against the same volumes with logging forced to stdout:

```bash
docker run --rm \
  -v /Volume1/public/config/mosquitto/config:/mosquitto/config \
  -v /Volume1/public/config/mosquitto/data:/mosquitto/data \
  -v /Volume1/public/config/mosquitto/log:/mosquitto/log \
  eclipse-mosquitto mosquitto -c /mosquitto/config/mosquitto.conf -v
```

A clean startup ends with `Opening ipv4 listen socket on port 1883.` and `mosquitto version 2.1.2 running` — if you see `password-file: Error: Unable to open pwfile` instead, it's the ownership issue above.

## Cambiare la password senza entrare nel container

Per Mosquitto puoi aggiornare la password anche senza `exec`, usando un container temporaneo con gli stessi volumi montati. Questo è spesso più robusto per amministrazione occasionale.

```bash
docker run --rm -it \
  -v /Volume1/public/config/mosquitto/config:/mosquitto/config \
  eclipse-mosquitto sh
```

Poi dentro:

```bash
mosquitto_passwd /mosquitto/config/passwd tuo_utente
```

Ricordati di riavviare il broker (`docker restart mqtt`) dopo la modifica, perché Mosquitto non ricarica automaticamente il file delle password.
