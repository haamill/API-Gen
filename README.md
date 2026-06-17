# CPA + NewAPI Deploy

Pure-script deployment for running CLIProxyAPI/CPAMC and NewAPI together on a fresh Ubuntu/Debian server.

The stack follows the upstream Docker deployment shape:

- CLIProxyAPI image: `eceasy/cli-proxy-api:latest`
- CPAMC management UI: built into CLIProxyAPI at `/management.html`
- NewAPI image: `calciumion/new-api:latest`
- NewAPI dependencies: Redis and Postgres
- Runtime: Docker Engine with Docker Compose v2 (`docker compose`)

## Quick Start

Run as `root` or with `sudo` on a fresh Ubuntu/Debian server:

```bash
git clone https://github.com/YOUR_NAME/cpa-newapi-deploy.git
cd cpa-newapi-deploy
sudo ./install.sh
sudo ./deploy.sh --host YOUR_SERVER_IP
```

If you do not pass `--host`, the script tries to detect the public IP and falls back to the first local IP.

## What Gets Created

Default install directory:

```text
/opt/cpa-newapi
├── docker-compose.yml
├── DEPLOYMENT_INFO.md
├── cpa/
│   ├── config.yaml
│   ├── auths/
│   └── logs/
└── new-api/
    ├── data/
    └── logs/
```

Default public URLs:

- CPA/CPAMC: `http://YOUR_SERVER_IP:8317/management.html`
- CPA API base: `http://YOUR_SERVER_IP:8317`
- NewAPI: `http://YOUR_SERVER_IP:3000`

The deploy script generates fresh secrets each run and writes them to:

```bash
/opt/cpa-newapi/DEPLOYMENT_INFO.md
```

Keep that file private.

## NewAPI Channel Setup

After containers start:

1. Open CPA/CPAMC: `http://YOUR_SERVER_IP:8317/management.html`
2. Log in with the CPA management key from `DEPLOYMENT_INFO.md`.
3. Add or log in to your provider accounts in CPA.
4. Open NewAPI: `http://YOUR_SERVER_IP:3000`
5. Complete the first-time NewAPI admin setup.
6. In NewAPI, add an OpenAI-compatible channel:
   - API address: `http://YOUR_SERVER_IP:8317`
   - Key: the CPA API key from `DEPLOYMENT_INFO.md`
   - Models: use the model names shown by CPA after login/OAuth is complete.
7. Configure model ratios/pricing and create NewAPI tokens for clients.

## Deploy Options

```bash
sudo ./deploy.sh \
  --install-dir /opt/cpa-newapi \
  --host YOUR_SERVER_IP \
  --timezone Asia/Shanghai \
  --cpa-port 8317 \
  --newapi-port 3000
```

Useful options:

- `--render-only`: render files without starting containers.
- `--force`: overwrite existing rendered files.
- `--cpa-image IMAGE`: override CLIProxyAPI image.
- `--newapi-image IMAGE`: override NewAPI image.

## Operations

Check status:

```bash
sudo docker compose -f /opt/cpa-newapi/docker-compose.yml ps
```

View logs:

```bash
sudo docker compose -f /opt/cpa-newapi/docker-compose.yml logs -f
```

Update images and restart:

```bash
sudo docker compose -f /opt/cpa-newapi/docker-compose.yml pull
sudo docker compose -f /opt/cpa-newapi/docker-compose.yml up -d
```

Stop:

```bash
sudo docker compose -f /opt/cpa-newapi/docker-compose.yml down
```

## Local Test

The render test does not require Docker:

```bash
bash tests/test_render.sh
```

Syntax checks:

```bash
bash -n install.sh
bash -n deploy.sh
```

## Security Notes

- Do not commit `DEPLOYMENT_INFO.md`, rendered `config.yaml`, or generated data directories.
- Put a firewall or reverse proxy in front of public ports if this is internet-facing.
- CLIProxyAPI remote management is enabled because this deployment expects browser access to CPAMC. Protect the generated management key.
- For HTTPS, terminate TLS with a reverse proxy such as Caddy, Nginx, or a cloud load balancer.
