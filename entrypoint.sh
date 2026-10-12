#!/bin/sh
set -eu
# Runs as root: never resolve commands from the orca-writable home.
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export HOME=/home/orca
: "${ORCA_PAIRING_ADDRESS:?set ORCA_PAIRING_ADDRESS}"

# Electron binary directly: the orca-ide wrapper can't pass --no-sandbox. Mirrors upstream's own Docker tests.
set -- env PATH="$HOME/.local/bin:$PATH" xvfb-run -a /opt/Orca/orca-ide --no-sandbox serve --port 6768 --pairing-address "$ORCA_PAIRING_ADDRESS" "$@"

# Started with --user: nothing to remap.
[ "$(id -u)" = 0 ] || exec "$@"

PUID=${PUID:-1000}
PGID=${PGID:-1000}
# Numeric test: rejects 0, 00 and non-numbers alike.
[ "$PUID" -gt 0 ] 2>/dev/null && [ "$PGID" -gt 0 ] 2>/dev/null || { echo "PUID/PGID must be positive integers" >&2; exit 1; }
groupmod --non-unique --gid "$PGID" orca
usermod --non-unique --uid "$PUID" --gid "$PGID" orca >/dev/null
# Only walk the volume when ownership is wrong (first start or changed PUID/PGID).
[ "$(stat -c %u:%g /home/orca)" = "$PUID:$PGID" ] || chown -R "$PUID:$PGID" /home/orca

exec setpriv --reuid "$PUID" --regid "$PGID" --init-groups --no-new-privs "$@"
