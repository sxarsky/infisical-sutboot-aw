#!/usr/bin/env bash
# Brings up the Infisical stack (nginx, backend, frontend, db, redis, pebble, technitium)
# from PR source via docker-compose.bdd.yml, mirroring .github/workflows/run-backend-bdd-tests.yml.
set -euo pipefail

echo "==> Freeing disk space and pruning stale Docker state"
sudo rm -rf /usr/share/dotnet /opt/ghc "/usr/local/share/boost" "${AGENT_TOOLSDIRECTORY:-}" || true
docker system prune -af || true

echo "==> Writing backend .env for SUT bring-up"
cp .env.dev.example .env
{
  echo "ACME_DEVELOPMENT_MODE=true"
  echo 'ACME_DEVELOPMENT_HTTP01_CHALLENGE_HOST_OVERRIDES={"localhost": "host.docker.internal:8087", "infisical.com": "host.docker.internal:8087", "example.com": "host.docker.internal:8087"}'
  echo "BDD_NOCK_API_ENABLED=true"
  echo "ACME_DNS_RESOLVE_RESOLVER_SERVERS_HOST_ENABLED=true"
  echo "ACME_DNS_RESOLVER_SERVERS=technitium"
  echo "ACME_SKIP_UPSTREAM_VALIDATION=true"
} >> .env

NEW_ENCRYPTION_KEY=6c1fe4e407b8911c104518103505b218
sed -i "s#ENCRYPTION_KEY=.*#ENCRYPTION_KEY=$NEW_ENCRYPTION_KEY#" .env
# No Mailhog/SMTP relay available in Testbot's CI -- disable so email sends don't fail requests
sed -i "s#SMTP_HOST=.*#SMTP_HOST=#" .env
sed -i "s#SMTP_PORT=.*#SMTP_PORT=#" .env
sed -i "s#SMTP_FROM_ADDRESS=.*#SMTP_FROM_ADDRESS=#" .env
sed -i "s#SMTP_FROM_NAME=.*#SMTP_FROM_NAME=#" .env
sed -i "s#SMTP_REQUIRE_TLS=.*#SMTP_REQUIRE_TLS=#" .env
sed -i "s#SMTP_USERNAME=.*#SMTP_USERNAME=#" .env
sed -i "s#SMTP_PASSWORD=.*#SMTP_PASSWORD=#" .env

# Enable ACME/SCEP feature flags in the license so PKI ACME/SCEP endpoints are testable
sed -i 's/pkiAcme: .*/pkiAcme: true,/g' backend/src/ee/services/license/license-fns.ts
sed -i 's/pkiScep: .*/pkiScep: true,/g' backend/src/ee/services/license/license-fns.ts

echo "==> Building and starting Infisical stack from PR source"
docker compose -f docker-compose.bdd.yml up -d --build
