#!/bin/sh
set -eu
: "${ORCA_PAIRING_ADDRESS:?set ORCA_PAIRING_ADDRESS}"

# Electron binary directly: the orca-ide wrapper can't pass --no-sandbox. Mirrors upstream's own Docker tests.
set -- xvfb-run -a /opt/Orca/orca-ide --no-sandbox serve --port 6768 --pairing-address "$ORCA_PAIRING_ADDRESS" "$@"

# Started with --user: nothing to remap.
[ "$(id -u)" = 0 ] || exec "$@"

PUID=${PUID:-1000}
PGID=${PGID:-1000}
groupmod --non-unique --gid "$PGID" orca
usermod --non-unique --uid "$PUID" --gid "$PGID" orca >/dev/null
# Only walk the volume when ownership is wrong (first start or changed PUID/PGID).
[ "$(stat -c %u:%g /home/orca)" = "$PUID:$PGID" ] || chown -R "$PUID:$PGID" /home/orca

exec setpriv --reuid "$PUID" --regid "$PGID" --init-groups "$@"
