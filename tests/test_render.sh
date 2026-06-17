#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

INSTALL_DIR="$TMP_DIR/app"

"$ROOT_DIR/deploy.sh" \
  --render-only \
  --force \
  --install-dir "$INSTALL_DIR" \
  --host example.com \
  --timezone UTC

assert_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Expected file missing: $path" >&2
    exit 1
  fi
}

assert_contains() {
  local path="$1"
  local pattern="$2"
  if ! grep -Fq -- "$pattern" "$path"; then
    echo "Expected '$path' to contain: $pattern" >&2
    exit 1
  fi
}

assert_not_contains() {
  local path="$1"
  local pattern="$2"
  if grep -Fq -- "$pattern" "$path"; then
    echo "Expected '$path' not to contain: $pattern" >&2
    exit 1
  fi
}

COMPOSE_FILE="$INSTALL_DIR/docker-compose.yml"
CPA_CONFIG="$INSTALL_DIR/cpa/config.yaml"
INFO_FILE="$INSTALL_DIR/DEPLOYMENT_INFO.md"

assert_file "$COMPOSE_FILE"
assert_file "$CPA_CONFIG"
assert_file "$INFO_FILE"

assert_contains "$COMPOSE_FILE" "eceasy/cli-proxy-api:latest"
assert_contains "$COMPOSE_FILE" "calciumion/new-api:latest"
assert_contains "$COMPOSE_FILE" "POSTGRES_PASSWORD:"
assert_contains "$COMPOSE_FILE" "redis-server"
assert_contains "$COMPOSE_FILE" "8317:8317"
assert_contains "$COMPOSE_FILE" "3000:3000"
assert_not_contains "$COMPOSE_FILE" "version:"

assert_contains "$CPA_CONFIG" "port: 8317"
assert_contains "$CPA_CONFIG" "allow-remote: true"
assert_contains "$CPA_CONFIG" "panel-github-repository: \"https://github.com/router-for-me/Cli-Proxy-API-Management-Center\""
assert_contains "$CPA_CONFIG" "api-keys:"
assert_not_contains "$CPA_CONFIG" "__"

assert_contains "$INFO_FILE" "CPA management: http://example.com:8317/management.html"
assert_contains "$INFO_FILE" "NewAPI: http://example.com:3000"
assert_contains "$INFO_FILE" "API address: http://example.com:8317"
assert_contains "$INFO_FILE" "docker compose -f $COMPOSE_FILE ps"
