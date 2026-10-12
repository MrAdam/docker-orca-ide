#!/bin/sh
# Usage: smoke-test.sh IMAGE — passes once the container reports healthy.
set -eu
docker run -d --name orca-smoke -e ORCA_PAIRING_ADDRESS=127.0.0.1 "$1" >/dev/null
trap 'docker rm -f orca-smoke >/dev/null' EXIT
for _ in $(seq 1 30); do
  [ "$(docker inspect -f '{{.State.Health.Status}}' orca-smoke)" = healthy ] && exit 0
  sleep 5
done
docker logs orca-smoke
exit 1
