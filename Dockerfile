FROM ubuntu:26.04@sha256:f144425ff09be612d6d9ad965196e9cdc23dae1f42110a8a11a3e9a8198759f7

# renovate: datasource=github-releases depName=stablyai/orca
ARG ORCA_VERSION=1.4.224
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl git jq openssh-client tini \
  && curl -fsSLo /tmp/orca.deb "https://github.com/stablyai/orca/releases/download/v${ORCA_VERSION}/orca-ide_${ORCA_VERSION}_${TARGETARCH}.deb" \
  # Verify against the digest GitHub records for the release asset.
  && curl -fsSL "https://api.github.com/repos/stablyai/orca/releases/tags/v${ORCA_VERSION}" \
    | jq -r --arg n "orca-ide_${ORCA_VERSION}_${TARGETARCH}.deb" '.assets[] | select(.name == $n) | .digest | sub("^sha256:"; "")' \
    | sed 's|$|  /tmp/orca.deb|' | sha256sum -c - \
  # libasound2t64/libgbm1/xauth: Electron + xvfb-run need them but the .deb omits them.
  && apt-get install -y --no-install-recommends /tmp/orca.deb libasound2t64 libgbm1 xauth \
  && rm -rf /tmp/orca.deb /var/lib/apt/lists/*

# ponytail: fixed uid 99/gid 100 (Unraid's nobody:users); add PUID/PGID remapping if used elsewhere.
RUN useradd --uid 99 --gid users --create-home --home-dir /home/orca --shell /bin/bash orca
USER orca
WORKDIR /home/orca
ENV PATH=/home/orca/.local/bin:$PATH
# The .deb lacks the orcad serve entry, so go straight to the Electron runtime.
ENV ORCA_SERVE_RUNTIME=electron

EXPOSE 6768
VOLUME ["/home/orca"]
HEALTHCHECK --start-period=60s CMD curl -fsS -o /dev/null http://127.0.0.1:6768/web-index.html || exit 1

# Electron binary directly: the orca-ide wrapper can't pass --no-sandbox. Mirrors upstream's own Docker tests.

ENTRYPOINT ["tini", "--", "sh", "-c", "exec xvfb-run -a /opt/Orca/orca-ide --no-sandbox serve --port 6768 --pairing-address \"${ORCA_PAIRING_ADDRESS:?set ORCA_PAIRING_ADDRESS}\" \"$@\"", "--"]
