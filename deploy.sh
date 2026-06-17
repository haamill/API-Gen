#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/opt/cpa-newapi"
HOST=""
TIMEZONE="Asia/Shanghai"
FORCE=0
RENDER_ONLY=0

CPA_IMAGE="eceasy/cli-proxy-api:latest"
NEWAPI_IMAGE="calciumion/new-api:latest"
CPA_PORT="8317"
CPA_REDIS_PORT="8085"
CPA_ANTHROPIC_PORT="1455"
CPA_CODEX_WS_PORT="54545"
CPA_CODEX_PORT="51121"
CPA_GEMINI_PORT="11451"
NEWAPI_PORT="3000"
POSTGRES_USER="root"
POSTGRES_DB="new-api"

usage() {
  cat <<'USAGE'
Usage: ./deploy.sh [options]

Options:
  --install-dir PATH        Install/render directory (default: /opt/cpa-newapi)
  --host HOST               Public host or IP shown in deployment info
  --timezone TZ             Container timezone (default: Asia/Shanghai)
  --cpa-port PORT           Public CLIProxyAPI/CPAMC port (default: 8317)
  --newapi-port PORT        Public NewAPI port (default: 3000)
  --cpa-image IMAGE         CLIProxyAPI image (default: eceasy/cli-proxy-api:latest)
  --newapi-image IMAGE      NewAPI image (default: calciumion/new-api:latest)
  --force                   Overwrite rendered files
  --render-only             Render files but do not start containers
  -h, --help                Show this help
USAGE
}

die() {
  echo "Error: $*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

random_hex() {
  local bytes="${1:-32}"
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex "$bytes"
  else
    od -An -N "$bytes" -tx1 /dev/urandom | tr -d ' \n'
  fi
}

detect_host() {
  if [[ -n "$HOST" ]]; then
    return
  fi
  if command -v curl >/dev/null 2>&1; then
    HOST="$(curl -fsS --max-time 2 https://api.ipify.org 2>/dev/null || true)"
  fi
  if [[ -z "$HOST" ]]; then
    HOST="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
  fi
  if [[ -z "$HOST" ]]; then
    HOST="YOUR_SERVER_IP"
  fi
}

replace_token() {
  local file="$1"
  local token="$2"
  local value="$3"
  local escaped
  escaped="$(printf '%s' "$value" | sed 's/[\/&]/\\&/g')"
  sed -i "s/__${token}__/${escaped}/g" "$file"
}

render_template() {
  local src="$1"
  local dst="$2"
  cp "$src" "$dst"
  replace_token "$dst" CPA_IMAGE "$CPA_IMAGE"
  replace_token "$dst" NEWAPI_IMAGE "$NEWAPI_IMAGE"
  replace_token "$dst" CPA_PORT "$CPA_PORT"
  replace_token "$dst" CPA_REDIS_PORT "$CPA_REDIS_PORT"
  replace_token "$dst" CPA_ANTHROPIC_PORT "$CPA_ANTHROPIC_PORT"
  replace_token "$dst" CPA_CODEX_WS_PORT "$CPA_CODEX_WS_PORT"
  replace_token "$dst" CPA_CODEX_PORT "$CPA_CODEX_PORT"
  replace_token "$dst" CPA_GEMINI_PORT "$CPA_GEMINI_PORT"
  replace_token "$dst" NEWAPI_PORT "$NEWAPI_PORT"
  replace_token "$dst" POSTGRES_USER "$POSTGRES_USER"
  replace_token "$dst" POSTGRES_DB "$POSTGRES_DB"
  replace_token "$dst" POSTGRES_PASSWORD "$POSTGRES_PASSWORD"
  replace_token "$dst" REDIS_PASSWORD "$REDIS_PASSWORD"
  replace_token "$dst" NEWAPI_SESSION_SECRET "$NEWAPI_SESSION_SECRET"
  replace_token "$dst" CPA_MANAGEMENT_KEY "$CPA_MANAGEMENT_KEY"
  replace_token "$dst" CPA_API_KEY "$CPA_API_KEY"
  replace_token "$dst" TIMEZONE "$TIMEZONE"
}

write_info() {
  cat >"$INSTALL_DIR/DEPLOYMENT_INFO.md" <<EOF
# CPA + NewAPI Deployment

## Paths

- Install dir: \`$INSTALL_DIR\`
- Compose file: \`$INSTALL_DIR/docker-compose.yml\`
- CPA config: \`$INSTALL_DIR/cpa/config.yaml\`

## URLs

- CPA management: http://$HOST:$CPA_PORT/management.html
- CPA API base: http://$HOST:$CPA_PORT
- NewAPI: http://$HOST:$NEWAPI_PORT

## Secrets

- CPA management key: \`$CPA_MANAGEMENT_KEY\`
- CPA API key for NewAPI channel: \`$CPA_API_KEY\`
- NewAPI session secret: \`$NEWAPI_SESSION_SECRET\`
- Postgres password: \`$POSTGRES_PASSWORD\`
- Redis password: \`$REDIS_PASSWORD\`

## NewAPI Channel

After first-time NewAPI admin setup, add an OpenAI-compatible channel:

- API address: http://$HOST:$CPA_PORT
- Key: \`$CPA_API_KEY\`
- Models: use the model names shown by CPA after OAuth/login is completed.

## Useful Commands

\`\`\`bash
docker compose -f $INSTALL_DIR/docker-compose.yml ps
docker compose -f $INSTALL_DIR/docker-compose.yml logs -f
docker compose -f $INSTALL_DIR/docker-compose.yml pull
docker compose -f $INSTALL_DIR/docker-compose.yml up -d
\`\`\`
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-dir) INSTALL_DIR="${2:?}"; shift 2 ;;
    --host) HOST="${2:?}"; shift 2 ;;
    --timezone) TIMEZONE="${2:?}"; shift 2 ;;
    --cpa-port) CPA_PORT="${2:?}"; shift 2 ;;
    --newapi-port) NEWAPI_PORT="${2:?}"; shift 2 ;;
    --cpa-image) CPA_IMAGE="${2:?}"; shift 2 ;;
    --newapi-image) NEWAPI_IMAGE="${2:?}"; shift 2 ;;
    --force) FORCE=1; shift ;;
    --render-only) RENDER_ONLY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

need_cmd sed
need_cmd cp
need_cmd mkdir

detect_host

COMPOSE_FILE="$INSTALL_DIR/docker-compose.yml"
CPA_CONFIG_FILE="$INSTALL_DIR/cpa/config.yaml"

if [[ "$FORCE" -ne 1 && ( -e "$COMPOSE_FILE" || -e "$CPA_CONFIG_FILE" ) ]]; then
  die "Rendered files already exist in $INSTALL_DIR. Re-run with --force to overwrite."
fi

POSTGRES_PASSWORD="$(random_hex 32)"
REDIS_PASSWORD="$(random_hex 32)"
NEWAPI_SESSION_SECRET="$(random_hex 32)"
CPA_MANAGEMENT_KEY="$(random_hex 24)"
CPA_API_KEY="$(random_hex 24)"

mkdir -p "$INSTALL_DIR/cpa/auths" "$INSTALL_DIR/cpa/logs" "$INSTALL_DIR/new-api/data" "$INSTALL_DIR/new-api/logs"

render_template "$SCRIPT_DIR/templates/docker-compose.yml.tpl" "$COMPOSE_FILE"
render_template "$SCRIPT_DIR/templates/cpa-config.yaml.tpl" "$CPA_CONFIG_FILE"
write_info

echo "Rendered deployment files in $INSTALL_DIR"

if [[ "$RENDER_ONLY" -eq 1 ]]; then
  echo "Render-only mode enabled; containers were not started."
  exit 0
fi

if ! docker compose version >/dev/null 2>&1; then
  die "Docker Compose v2 is not available. Run ./install.sh first."
fi

docker compose -f "$COMPOSE_FILE" up -d

echo
echo "Deployment started."
echo "Open: http://$HOST:$CPA_PORT/management.html"
echo "Open: http://$HOST:$NEWAPI_PORT"
echo "Details: $INSTALL_DIR/DEPLOYMENT_INFO.md"
