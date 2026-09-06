#!/bin/sh
# Writes a consistent copy of the running instance's database to ./backups.
# The api binary copies the SQLite file with VACUUM INTO, which is safe while
# the server is writing; the copy is then pulled out of the container.
# Usage: deploy/backup.sh [compose args...]   e.g. deploy/backup.sh -f docker-compose.yml
set -eu
stamp="$(date +%Y%m%d-%H%M%S)"
mkdir -p backups
docker compose "$@" exec api /showdown -backup "/tmp/backup-$stamp.sqlite"
docker compose "$@" cp "api:/tmp/backup-$stamp.sqlite" "backups/showdown-$stamp.sqlite"
echo "backups/showdown-$stamp.sqlite"
