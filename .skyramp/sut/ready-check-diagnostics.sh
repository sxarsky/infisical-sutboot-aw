#!/usr/bin/env bash
# Surfaced in the failure PR comment when targetReadyCheckCommand times out.
set -uo pipefail

echo "==== docker compose ps ===="
docker compose -f docker-compose.bdd.yml ps

echo "==== backend logs (tail) ===="
docker compose -f docker-compose.bdd.yml logs --tail=200 backend

echo "==== frontend logs (tail) ===="
docker compose -f docker-compose.bdd.yml logs --tail=100 frontend

echo "==== nginx logs (tail) ===="
docker compose -f docker-compose.bdd.yml logs --tail=100 nginx
