#!/usr/bin/env bash
# Sobe o container (se preciso) e aplica schema + seed.
source "$(dirname "$0")/lib.sh"

docker compose -f "$ROOT_DIR/docker-compose.yml" up -d
init_db
