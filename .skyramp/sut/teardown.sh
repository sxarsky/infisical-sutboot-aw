#!/usr/bin/env bash
# Stops the SUT stack and cleans up so the next Testbot fix-loop retry starts from a clean slate.
set -uo pipefail

echo "==> Tearing down Infisical SUT stack"
docker compose -f docker-compose.bdd.yml down -v --remove-orphans

echo "==> Pruning Docker build cache and dangling images"
docker system prune -af
docker builder prune -af
