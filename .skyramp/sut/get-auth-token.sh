#!/usr/bin/env bash
# Bootstraps the first (unauthenticated, one-time) admin account on the freshly-started SUT
# and prints a bearer token to stdout, mirroring backend/bdd/features/environment.py's
# bootstrap_infisical(): admin signup -> select-organization -> refresh -> access token.
# POST /api/v1/admin/signup only succeeds once (while serverCfg.initialized is false),
# which holds here because the SUT's Postgres volume is recreated fresh on every setup.
set -euo pipefail

BASE_URL="${INFISICAL_API_URL:-http://localhost:8080}"
COOKIE_JAR="$(mktemp)"
trap 'rm -f "$COOKIE_JAR"' EXIT

EMAIL="testbot-admin-$(date +%s)@infisical.com"
PASSWORD="Testbot@12345!"
FIRST_NAME="Testbot"
LAST_NAME="Admin"

# select-organization and auth/token both read the "jid" refresh-token cookie set by signup,
# so all three calls must share one cookie jar.
signup_resp=$(curl -sf -c "$COOKIE_JAR" -b "$COOKIE_JAR" -X POST "$BASE_URL/api/v1/admin/signup" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"firstName\":\"$FIRST_NAME\",\"lastName\":\"$LAST_NAME\"}")

temp_token=$(echo "$signup_resp" | jq -r '.token')
org_id=$(echo "$signup_resp" | jq -r '.organization.id')

select_org_resp=$(curl -sf -c "$COOKIE_JAR" -b "$COOKIE_JAR" -X POST "$BASE_URL/api/v3/auth/select-organization" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $temp_token" \
  -d "{\"organizationId\":\"$org_id\"}")

session_token=$(echo "$select_org_resp" | jq -r '.token')

auth_resp=$(curl -sf -c "$COOKIE_JAR" -b "$COOKIE_JAR" -X POST "$BASE_URL/api/v1/auth/token" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $session_token" \
  -d '{}')

echo "$auth_resp" | jq -r '.token'
