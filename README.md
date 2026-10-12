# docker-orca-ide

Unofficial Docker image running [Orca](https://github.com/stablyai/orca) headless via `orca serve`, so desktop, web and mobile clients can pair with it.

```sh
mkdir -p /mnt/user/appdata/orca-ide && chown 99:100 /mnt/user/appdata/orca-ide
docker run -d --name orca-ide \
  -p 6768:6768 \
  -e ORCA_PAIRING_ADDRESS=100.x.y.z \
  -v /mnt/user/appdata/orca-ide:/home/orca \
  ghcr.io/mradam/orca-ide:latest
docker logs orca-ide   # prints the pairing URL
```

Paste the pairing URL into **Settings → Remote Orca Servers → Add Server** in the Orca desktop app. On Unraid, use `unraid-template.xml`.

Install and log in to agent CLIs from inside the container (`docker exec -it orca-ide bash`); they persist in `/home/orca`:

```sh
curl -fsSL https://claude.ai/install.sh | bash
orca account add --agent claude
```

## Security

- Keep port 6768 on your LAN or tailnet. Never expose it to the internet.
- The pairing URL grants full access. Treat it like a password.
- No keyring in the container, so Orca stores secrets unencrypted in `/home/orca`. Protect that volume.

## Tags

- `latest`: newest release
- `X.Y.Z`: this repo's release (release-please)
- `orca-X.Y.Z`: the bundled Orca version

Renovate bumps Orca, the base image and actions; merging the release-please PR publishes the image.
