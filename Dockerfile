FROM ubuntu:26.04@sha256:f144425ff09be612d6d9ad965196e9cdc23dae1f42110a8a11a3e9a8198759f7

# renovate: datasource=github-releases depName=stablyai/orca
ARG ORCA_VERSION=1.4.229
# renovate: datasource=github-releases depName=cli/cli
ARG GH_VERSION=2.102.0
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

# Orca's GitHub features (PRs, reviews, checks) shell out to gh.
RUN curl -fsSLo /tmp/gh.tar.gz "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${TARGETARCH}.tar.gz" \
  && curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_checksums.txt" \
    | grep " gh_${GH_VERSION}_linux_${TARGETARCH}.tar.gz$" \
    | sed 's|  .*|  /tmp/gh.tar.gz|' | sha256sum -c - \
  && tar -xzf /tmp/gh.tar.gz -C /usr/local --strip-components=1 "gh_${GH_VERSION}_linux_${TARGETARCH}/bin/gh" \
  && rm /tmp/gh.tar.gz

# Drop the base image's `ubuntu` user so `orca` can take uid/gid 1000; entrypoint.sh remaps to PUID/PGID.
RUN userdel --remove ubuntu \
  && useradd --uid 1000 --user-group --create-home --home-dir /home/orca --shell /bin/bash orca
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
WORKDIR /home/orca
# ~/.local/bin is orca-writable, so it's never on root's PATH: entrypoint.sh adds it after the
# privilege drop, profile.d for `docker exec -u orca ... bash -l` (HOME comes from passwd, not ENV).
RUN echo 'PATH="$HOME/.local/bin:$PATH"' > /etc/profile.d/orca-path.sh
# The .deb lacks the orcad serve entry, so go straight to the Electron runtime.
ENV ORCA_SERVE_RUNTIME=electron

EXPOSE 6768
VOLUME ["/home/orca"]
HEALTHCHECK --start-period=60s CMD curl -fsS -o /dev/null http://127.0.0.1:6768/web-index.html || exit 1

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
