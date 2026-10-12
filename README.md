<div align="center">

# 🐋 docker-orca-ide

**Run a headless [Orca](https://github.com/stablyai/orca) server in a container. Your agents keep working after your laptop goes to sleep.**

[![CI](https://github.com/MrAdam/docker-orca-ide/actions/workflows/ci.yml/badge.svg)](https://github.com/MrAdam/docker-orca-ide/actions/workflows/ci.yml)
[![Release](https://github.com/MrAdam/docker-orca-ide/actions/workflows/release.yml/badge.svg)](https://github.com/MrAdam/docker-orca-ide/actions/workflows/release.yml)
[![Upstream Orca](https://img.shields.io/github/v/release/stablyai/orca?label=upstream%20orca&logo=github)](https://github.com/stablyai/orca/releases)
[![Renovate](https://img.shields.io/badge/renovate-enabled-1A1F6C?logo=renovatebot)](https://docs.renovatebot.com)
[![GHCR](https://img.shields.io/badge/ghcr.io-mradam%2Forca--ide-2496ED?logo=docker&logoColor=white)](https://github.com/MrAdam/docker-orca-ide/pkgs/container/orca-ide)

</div>

---

Orca can run as a remote server: one machine holds the repos, terminals and agent sessions, and you connect to it from the desktop app, the browser or your phone. Upstream ships no container for this, so this repo packages one.

> [!NOTE]
> This is an unofficial image and isn't affiliated with Stably.

## ✨ What's inside

- 📦 The official Orca `.deb`, checked against the SHA-256 digest of the GitHub release asset
- 👤 Runs as an unprivileged user, with configurable `PUID`/`PGID`
- 🩺 Built-in healthcheck, plus `tini` as PID 1 so agent processes get cleaned up
- 🔁 Renovate keeps Orca, the base image and the GitHub Actions up to date
- 🔏 Images ship with an SBOM and build provenance, and Trivy scans every build

## 🚀 Quick start

```sh
docker run -d --name orca-ide \
  -p 6768:6768 \
  -e ORCA_PAIRING_ADDRESS=100.x.y.z \
  -v ./orca:/home/orca \
  ghcr.io/mradam/orca-ide:latest

docker logs orca-ide   # 👈 copy the pairing URL
```

Then open **Settings → Remote Orca Servers → Add Server** in the Orca desktop app and paste the pairing URL.

<details>
<summary><b>Docker Compose</b></summary>

```yaml
services:
  orca-ide:
    image: ghcr.io/mradam/orca-ide:latest
    restart: unless-stopped
    ports:
      - "6768:6768"
    environment:
      ORCA_PAIRING_ADDRESS: 100.x.y.z
    volumes:
      - ./orca:/home/orca
```

</details>

## ⚙️ Configuration

| | Value | Purpose |
| --- | --- | --- |
| **Env** | `ORCA_PAIRING_ADDRESS` | *Required.* The address clients connect to, such as a Tailscale IP |
| **Env** | `PUID` / `PGID` | User and group IDs Orca runs as (default `1000`). The volume is chowned to match |
| **Port** | `6768` | WebSocket runtime and web client |
| **Volume** | `/home/orca` | Orca state, agent CLIs, credentials and repos |

Arguments after the image name are passed through to `orca serve`, for example `--mobile-pairing`.

## 🤖 Agents

The image doesn't include any agent CLIs. Install them once from a shell in the container, as the `orca` user (`-u orca`). They're stored on the volume, so image updates keep them:

```sh
docker exec -it -u orca orca-ide bash
curl -fsSL https://claude.ai/install.sh | bash
orca account add --agent claude
```

## 🔒 Security

> [!WARNING]
> Whoever has the pairing URL has full shell access to the container.

- Only expose port `6768` on your LAN or tailnet, never to the public internet.
- There's no keyring in the container, so Orca stores secrets unencrypted on the volume. Protect the volume.

## 🏷️ Tags

| Tag | Meaning |
| --- | --- |
| `latest` | Newest release |
| `X.Y.Z` | This repo's release, cut by release-please |
| `orca-X.Y.Z` | Pinned to a specific upstream Orca version |
