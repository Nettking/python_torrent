# python_torrent

A minimal, Docker-based [Transmission](https://transmissionbt.com/) BitTorrent client deployment using the [LinuxServer.io Transmission image](https://docs.linuxserver.io/images/docker-transmission/).

**Despite the repository name, this is not a Python package or a custom torrent client.** The repository currently contains a Docker Compose configuration and an optional Dockerfile; Transmission provides the web interface and torrent functionality.

## Requirements

- Docker Engine with the Docker Compose plugin (`docker compose`)
- Host ports `9091/tcp` and `51413/tcp+udp` available (unless you change the mappings)
- Writable storage for Transmission settings and downloaded files

## Quick start

1. Clone the repository and enter its directory:

   ```sh
   git clone https://github.com/Nettking/python_torrent.git
   cd python_torrent
   ```

2. **Before starting the service, edit `docker-compose.yml`:** replace the committed `USER` and `PASS` values with credentials unique to your deployment. The password currently in the repository is public and **must not be considered secure**. Adjust `PUID`, `PGID`, and `TZ` to match your host, and consider limiting access to port 9091 as described under [Security](#security).

3. Create the bind-mount directories:

   ```sh
   mkdir -p config downloads watch
   ```

4. Validate the Compose file and start Transmission:

   ```sh
   docker compose config --quiet
   docker compose up -d
   docker compose ps
   ```

5. Open `http://localhost:9091` in a browser **on the Docker host**, or `http://<host-ip>:9091` from another device if the host firewall and the Compose port binding permit access. Sign in with the `USER` and `PASS` values you configured.

You can add torrents through the web interface, or place `.torrent` files in the host's `watch/` directory for Transmission's watch-folder functionality.

## Repository files

| Path | Purpose |
| --- | --- |
| `docker-compose.yml` | **Primary deployment configuration.** Pulls `linuxserver/transmission:latest`, publishes ports, sets environment variables, and mounts directories. |
| `dockerfile` | Optional, standalone Dockerfile based on the same upstream image. **Not used** by the current Compose service, which has an `image:` entry and no `build:` entry. |
| `README.md` | Setup, configuration, and operations documentation. |

## Configuration

The checked-in `docker-compose.yml` defines these environment variables:

| Variable | Current setting | Meaning |
| --- | --- | --- |
| `PUID` | `1000` | Host user ID used for file ownership inside the LinuxServer.io container. |
| `PGID` | `1000` | Host group ID used for file ownership. |
| `TZ` | `Europe/Oslo` | Container timezone. |
| `USER` | `admin` | Transmission web interface username; change before use. |
| `PASS` | Hard-coded in Compose | Transmission web interface password; replace before use and do not reuse it elsewhere. |
| `PEERPORT` | `51413` | Torrent peer-listening port; keep it aligned with the published TCP/UDP mappings. |

On Linux, `id -u` and `id -g` show your current user and group IDs. The configured IDs must be able to write to the bind-mounted directories.

### Ports

| Host mapping | Purpose |
| --- | --- |
| `9091:9091/tcp` | Transmission web UI and RPC endpoint. |
| `51413:51413/tcp` | BitTorrent peer connections over TCP. |
| `51413:51413/udp` | BitTorrent peer connections over UDP. |

The current port mappings bind to all host network interfaces by default. Changing the external web port (for example, `127.0.0.1:9091:9091`) can limit web access to the host; if you change the internal peer port, update `PEERPORT` and both peer-port mappings consistently.

### Persistent directories

All paths below are relative to the directory containing `docker-compose.yml`.

| Host directory | Container directory | Purpose |
| --- | --- | --- |
| `./config` | `/config` | Transmission settings and application data. |
| `./downloads` | `/downloads` | Downloaded content. |
| `./watch` | `/watch` | Watched `.torrent` files. |

These are **bind mounts**, not Docker-managed named volumes. Their contents persist when the container is recreated or stopped, provided the host directories are retained.

## Everyday operations

Run these commands from the repository root:

```sh
# Inspect the container and follow logs
docker compose ps
docker compose logs -f transmission

# Restart the service
docker compose restart transmission

# Update the upstream image and recreate the service
docker compose pull
docker compose up -d

# Stop and remove the service container/network (keeps bind-mounted data)
docker compose down
```

The Compose service has `restart: unless-stopped`, so Docker will normally restart it after a failure or host reboot unless it was explicitly stopped.

**Backups:** Back up `config/` for settings and state, and `downloads/` for content you need to retain. Stop the service before taking a consistent backup of its configuration. Do not commit runtime data or private credentials to Git.

## Security

> **Important:** The current Compose file contains a hard-coded login and password in a **public repository**. Treat those credentials as exposed. Replace them before deployment, rotate them on existing deployments, and do not commit replacement secrets.

- Web traffic on port `9091` is plain HTTP in this configuration; a password alone does **not** provide TLS encryption. Prefer a trusted private network, a VPN/SSH tunnel, or a properly secured HTTPS reverse proxy.
- Avoid exposing port `9091` to the public internet. If access is local only, consider changing the binding to `127.0.0.1:9091:9091`. Peer ports `51413/tcp+udp` serve a different purpose and can be managed separately.
- Restrict access to `config/` and `downloads/` at the host filesystem level. Docker environment variables may be visible to users with Docker/host administrative access.
- `latest` is a moving upstream image tag: review upstream changes when updating. Pin an image version or digest if repeatable deployments are required.
- The standalone `dockerfile` also contains an example password; do not publish or deploy an image that relies on that default.
- The repository does **not** currently include a reverse proxy, HTTPS termination, secrets management, or automated backup configuration.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Web UI does not open | Run `docker compose ps` and `docker compose logs transmission`; check host firewall rules and whether TCP port 9091 is already in use. |
| Sign-in fails | Confirm the `USER` and `PASS` environment values in the Compose service, then recreate it with `docker compose up -d`. |
| Downloads cannot be written | Check ownership and permissions of `downloads/` and `config/` against `PUID`/`PGID`. |
| Slow/incoming peer connections fail | Check TCP and UDP port 51413 mappings, host firewall, router/NAT forwarding if needed, and whether `PEERPORT` matches. |
| A manual settings change disappears | Stop the container before editing `config/settings.json`; Transmission may overwrite changes made while running. Use `USER`/`PASS` in Compose for authentication instead of editing these directly into `settings.json`. |

For image-specific environment variables and detailed troubleshooting, see the [official LinuxServer.io Transmission documentation](https://docs.linuxserver.io/images/docker-transmission/).

## Optional Dockerfile

The lowercase `dockerfile` is not automatically built by the provided Compose file. To build it explicitly:

```sh
docker build -f dockerfile -t transmission-local:latest .
```

This creates a local image, **but it does not change the Compose deployment**. To use that image with Compose you would need to modify the service's `image:` or `build:` configuration. Review the Dockerfile's environment defaults, especially credentials, before running it.
