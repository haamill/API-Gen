# CPA NewAPI Deploy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a pure-script deployment project for CLIProxyAPI/CPAMC plus NewAPI on fresh Ubuntu/Debian servers.

**Architecture:** Use Bash scripts with template rendering. Keep Docker installation, stack rendering, deployment, and tests separate so the scripts can be verified without changing the current server.

**Tech Stack:** Bash, Docker Engine, Docker Compose v2 plugin, YAML templates.

---

### Task 1: Render-Only Test

**Files:**
- Create: `tests/test_render.sh`

- [ ] **Step 1: Write the failing test**

Create `tests/test_render.sh` with assertions that call `deploy.sh --render-only --force --install-dir "$tmpdir/app" --host example.com` and check generated `docker-compose.yml`, `cpa/config.yaml`, and `DEPLOYMENT_INFO.md`.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash cpa-newapi-deploy/tests/test_render.sh`

Expected: FAIL because `deploy.sh` does not exist yet.

### Task 2: Deployment Script And Templates

**Files:**
- Create: `deploy.sh`
- Create: `templates/docker-compose.yml.tpl`
- Create: `templates/cpa-config.yaml.tpl`

- [ ] **Step 1: Implement minimal script and templates**

Implement `deploy.sh` with strict mode, argument parsing, random secret generation, bcrypt management key hashing via Python if available or plaintext fallback accepted by CLIProxyAPI, template rendering, `--render-only`, `--force`, and `docker compose up -d` for live mode.

- [ ] **Step 2: Run render test**

Run: `bash cpa-newapi-deploy/tests/test_render.sh`

Expected: PASS.

### Task 3: Docker Installer

**Files:**
- Create: `install.sh`

- [ ] **Step 1: Add Docker Engine installer**

Implement apt-based Docker install for Ubuntu/Debian using Docker's official repository and packages `docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin`.

- [ ] **Step 2: Syntax-check installer**

Run: `bash -n cpa-newapi-deploy/install.sh`

Expected: no output, exit 0.

### Task 4: Documentation

**Files:**
- Create: `README.md`
- Create: `.gitignore`

- [ ] **Step 1: Document setup and operations**

Document clone/run commands, deploy options, generated paths, CPAMC/NewAPI URLs, NewAPI channel setup, logs, update, and security notes.

- [ ] **Step 2: Run final validation**

Run:

```bash
bash -n cpa-newapi-deploy/deploy.sh
bash -n cpa-newapi-deploy/install.sh
bash cpa-newapi-deploy/tests/test_render.sh
```

Expected: all pass.
