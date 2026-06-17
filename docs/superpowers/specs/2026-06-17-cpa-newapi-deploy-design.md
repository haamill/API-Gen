# CPA NewAPI Deploy Design

## Goal

Build a reusable GitHub-ready script project that deploys CLIProxyAPI/CPAMC and NewAPI together on a fresh Ubuntu/Debian server using Docker Engine and Docker Compose v2.

## Current Deployment Reference

The existing server runs CLIProxyAPI and NewAPI from public Docker images. CLIProxyAPI provides the CPAMC management UI at `/management.html`; CPAMC does not need a separate container. NewAPI connects to CLIProxyAPI by adding an OpenAI-compatible channel that points to the CLIProxyAPI base URL and uses a key from `api-keys` in `config.yaml`.

## Architecture

The project contains shell scripts and templates only. `install.sh` installs Docker Engine and the Compose v2 plugin from Docker's apt repository. `deploy.sh` generates secrets, renders Docker Compose and CLIProxyAPI config files, starts containers with `docker compose`, and writes a deployment summary.

## Components

- `install.sh`: Detect Debian/Ubuntu, configure Docker apt repository, install `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, and `docker-compose-plugin`.
- `deploy.sh`: Accept paths, host, ports, image tags, and `--render-only`; generate secrets when not provided; render templates; optionally run `docker compose up -d`.
- `templates/docker-compose.yml.tpl`: Compose stack for CLIProxyAPI, NewAPI, Redis, and Postgres.
- `templates/cpa-config.yaml.tpl`: CLIProxyAPI config with generated management key hash and API key.
- `tests/test_render.sh`: Verify render-only behavior without touching Docker.
- `README.md`: Document one-command deployment, manual NewAPI channel setup, update, logs, and security notes.

## Data Flow

`deploy.sh` creates an install directory, renders service files, and starts four containers on one Docker network. NewAPI uses Redis and Postgres internally. Users complete first-time NewAPI setup in the browser, then add a NewAPI OpenAI-compatible channel with `http://<host>:8317` and the generated CPA API key.

## Error Handling

Scripts use strict shell settings and fail fast with actionable messages. `install.sh` refuses unsupported operating systems. `deploy.sh` refuses to overwrite generated files unless `--force` is passed, validates required commands, and supports `--render-only` for safe testing.

## Testing

The test suite runs locally without Docker. It calls `deploy.sh --render-only` in a temporary directory and checks that the rendered files use Docker Compose v2-compatible syntax, generated keys are present, NewAPI points to generated Postgres/Redis credentials, and deployment instructions include the CPA channel details.
