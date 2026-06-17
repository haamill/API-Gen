#!/usr/bin/env bash
set -euo pipefail

die() {
  echo "Error: $*" >&2
  exit 1
}

need_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    die "Run this script as root, for example: sudo ./install.sh"
  fi
}

install_docker() {
  local distro
  local codename

  if [[ ! -r /etc/os-release ]]; then
    die "Cannot detect operating system. This installer supports Ubuntu and Debian."
  fi

  # shellcheck disable=SC1091
  . /etc/os-release
  distro="${ID:-}"
  codename="${VERSION_CODENAME:-}"

  case "$distro" in
    ubuntu|debian) ;;
    *) die "Unsupported OS: ${PRETTY_NAME:-unknown}. Use Ubuntu or Debian." ;;
  esac

  if [[ -z "$codename" ]]; then
    die "Cannot detect OS codename from /etc/os-release."
  fi

  apt-get update
  apt-get install -y ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings

  curl -fsSL "https://download.docker.com/linux/$distro/gpg" -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc

  cat >"/etc/apt/sources.list.d/docker.list" <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$distro $codename stable
EOF

  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  systemctl enable --now docker
}

need_root
install_docker

echo
docker --version
docker compose version
echo "Docker Engine and Docker Compose v2 are installed."
