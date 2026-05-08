---
name: docker-containerization
description: >-
  Dockerfile authoring, containerizing Python services (Flask, CLIs, Jira tooling),
  multi-stage builds, layer caching, non-root user, .dockerignore, secrets not baked
  into images, HEALTHCHECK, docker-compose for local dev, image scanning with trivy
  or docker scout, base image selection (slim, distroless, alpine tradeoffs). Triggers:
  Dockerfile, docker, containerize, container, docker-compose, multi-stage, base image,
  HEALTHCHECK, dockerignore, non-root, image build, docker build.
---

# docker-containerization

## What this is

Patterns and examples for containerizing Python internal tools — Flask services, CLI
scripts, Jira automation — using Docker. Covers everything from base image selection
through CI image scanning. Not a Docker tutorial; assumes you can run `docker build`.

**Related skills**

- `secrets-management` — secrets must never be baked into images; use that skill for
  vault patterns, CI secret injection, and gitleaks.
- `python-scripts-and-services` — Flask serving (`flask-serving.md`), project layout, venv.
- `python-scripts-and-services/security.md` — input validation, API key handling.

---

## 1. Base image selection

| Image | When to use | Avoid when |
|---|---|---|
| `python:3.12-slim` | Default for most internal tools | Never — always pin a version |
| `python:3.12-alpine` | Size matters most | Packages that need glibc (many compiled wheels fail on musl libc, e.g. some numpy builds, mysqlclient) |
| `gcr.io/distroless/python3` | Production hardening, no shell | You need a shell for debugging or complex ENTRYPOINT logic |
| `python:3.12` (full) | Rarely: only if slim/alpine both fail | CI speed — the full image is ~1 GB |

**Rules:**

- Never use `latest`. Always pin the full version: `python:3.12.9-slim-bookworm`.
  Unpinned tags change silently and break builds.
- Prefer `-slim-bookworm` (Debian bookworm slim) — good balance of size and glibc
  compatibility.
- Upgrade base images on a schedule (monthly) and rescan. Pin + update, not pin +
  forget.

```dockerfile
# Good
FROM python:3.12.9-slim-bookworm

# Bad — breaks silently when upstream updates
FROM python:latest
FROM python:3.12
```

---

## 2. Multi-stage builds

Use two stages: a **builder** that installs dependencies and a **final** stage that
copies only what is needed. This keeps the final image small and free of build tools.

```dockerfile
# ── Stage 1: builder ─────────────────────────────────────────────────────────
FROM python:3.12.9-slim-bookworm AS builder

WORKDIR /build

# Install build dependencies (only in builder)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
  && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Stage 2: final ───────────────────────────────────────────────────────────
FROM python:3.12.9-slim-bookworm AS final

# Copy only installed packages from builder — no gcc, no apt caches
COPY --from=builder /install /usr/local

WORKDIR /app
COPY src/ ./src/
COPY app/ ./app/
COPY scripts/ ./scripts/

# ... (non-root user, HEALTHCHECK, CMD — see sections below)
```

The final image inherits none of the build-time packages. If your app needs a runtime
system library (e.g. `libpq.so` for psycopg2), install it in the final stage too with
`apt-get install --no-install-recommends libpq5`.

---

## 3. Layer caching

Docker caches each layer. A changed layer invalidates every layer after it. The rule:
**copy files that change less often first**.

```dockerfile
WORKDIR /app

# Step 1 — copy only requirements, install deps.
# This layer is cached as long as requirements.txt doesn't change,
# even when your source code changes every commit.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Step 2 — copy source last. Cache miss here is cheap; no reinstall.
COPY src/ ./src/
COPY app/ ./app/
COPY scripts/ ./scripts/
```

Do NOT do this — it busts the dep cache on every source change:

```dockerfile
# Bad — copies everything first, so every code change reinstalls deps
COPY . .
RUN pip install -r requirements.txt
```

Other caching tips:

- Combine related `RUN` commands with `&&` into one layer to avoid intermediate image
  bloat.
- Always end `apt-get install` layers with `&& rm -rf /var/lib/apt/lists/*` to discard
  the package index from the layer.

---

## 4. Non-root user

Running as root inside a container is a significant risk. If the container process is
compromised, the attacker has root inside the container and easier paths to the host or
other containers.

```dockerfile
# Create a non-root user and group with no home dir write access to /app
RUN useradd --system --no-create-home --shell /usr/sbin/nologin appuser

# Give ownership of the app directory to that user
RUN chown -R appuser:appuser /app

# Switch to the non-root user for all subsequent instructions and at runtime
USER appuser
```

For multi-stage builds, add the `useradd` and `USER` instructions in the **final** stage
after all `COPY` commands, so the `chown` applies to the already-copied files.

Verify after build:

```bash
docker run --rm myimage whoami
# should print: appuser
```

---

## 5. .dockerignore

A `.dockerignore` file controls what gets sent to the Docker build context. Files in the
build context can be `COPY .`-ed into images. Without `.dockerignore`, secrets, test
artifacts, and large directories bloat the context and can leak into the image.

Create `.dockerignore` at the repo root:

```
# Secrets — MUST be excluded. config.yaml holds real tokens and passwords.
config.yaml
.env
*.env
secrets/

# Virtual environment — large, not needed; image installs from requirements.txt
.venv/
venv/
env/

# Python artifacts
__pycache__/
*.py[cod]
*.pyo
*.egg-info/
dist/
build/
.eggs/

# Test code — not needed in production images
tests/
.pytest_cache/
.coverage
coverage.xml
htmlcov/

# Docs — not needed at runtime
docs/
*.md

# Git history
.git/
.gitignore

# Editor / OS artifacts
.DS_Store
.idea/
.vscode/
*.swp
```

**Critical:** `config.yaml` must be in `.dockerignore` AND in `.gitignore`. A real
`config.yaml` with production tokens must never be baked into an image. If it is, any
team member with registry pull access can extract the secrets with `docker run --rm
myimage cat /app/config.yaml`.

To verify nothing sensitive made it in:

```bash
docker run --rm myimage find /app -name "config.yaml" -o -name ".env"
# should return nothing
```

---

## 6. Environment variables vs build args

| Mechanism | Scope | Visible in `docker history`? | For secrets? |
|---|---|---|---|
| `ARG` | Build time only | Yes — in layer metadata | Never |
| `ENV` | Runtime (baked in) | Yes — in image config | Only for non-secret config |
| Runtime `-e` flag | Runtime only | No | Yes |
| Docker secrets (mounted) | Runtime only | No | Yes (preferred) |

```dockerfile
# ARG — build-time substitution only, goes into image history
# Use for: build metadata (version, git SHA), not secrets
ARG APP_VERSION=unknown
LABEL app.version=$APP_VERSION

# ENV — runtime, visible in 'docker inspect'
# Use for: non-secret config like log level, port, timeout
ENV LOG_LEVEL=INFO \
    PORT=5000 \
    WORKERS=2
```

For secrets (tokens, passwords, API keys), pass at runtime:

```bash
# Runtime env var — never baked into image
docker run -e JIRA_TOKEN="$JIRA_TOKEN" myimage

# Or use Docker secrets (Swarm/Compose v3 secrets)
```

In your Python app, read config from environment variables as a fallback when no
config file is mounted:

```python
import os

def load_config() -> dict:
    cfg_path = Path(os.getenv("CONFIG_PATH", "config.yaml"))
    if cfg_path.exists():
        return yaml.safe_load(cfg_path.read_text())
    # Fallback: assemble from env vars (useful in containers)
    return {
        "jira": {
            "base_url": os.environ["JIRA_BASE_URL"],
            "token": os.environ["JIRA_TOKEN"],
        }
    }
```

---

## 7. HEALTHCHECK

A `HEALTHCHECK` instruction tells Docker (and orchestrators like Compose, Kubernetes,
ECS) whether the container is healthy. Without it, a container is reported healthy as
long as the process is running — even if the app is deadlocked.

For a Flask app on port 5000:

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" \
  || exit 1
```

Or using `curl` if you install it in the image:

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends curl \
  && rm -rf /var/lib/apt/lists/*

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:5000/health || exit 1
```

Add a `/health` endpoint to your Flask app that returns 200 with a minimal body:

```python
@app.get("/health")
def health() -> tuple[dict, int]:
    return {"status": "ok"}, 200
```

The health check should be lightweight — no DB queries, no external calls. It proves the
process is alive and the HTTP server is responding.

---

## 8. docker-compose for local dev

Use `docker-compose.yml` for local development so any team member can run the full stack
with one command. Keep production overrides separate.

**`docker-compose.yml`** — base, production-compatible:

```yaml
version: "3.9"

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    image: my-internal-tool:local
    ports:
      - "5000:5000"
    environment:
      - LOG_LEVEL=INFO
      - CONFIG_PATH=/run/secrets/config
    secrets:
      - config
    healthcheck:
      test: ["CMD", "python", "-c",
             "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"]
      interval: 30s
      timeout: 5s
      retries: 3
    depends_on:
      redis:
        condition: service_healthy
    restart: unless-stopped

  redis:
    image: redis:7.2-alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3
    restart: unless-stopped

secrets:
  config:
    file: ./config.yaml   # real config.yaml on your local machine, not committed
```

**`docker-compose.override.yml`** — dev-only additions (auto-merged by Compose when
present; never commit secrets here):

```yaml
version: "3.9"

services:
  app:
    build:
      target: builder   # use the builder stage for dev tools
    volumes:
      # Mount source for live reload — changes apply without rebuild
      - ./src:/app/src:ro
      - ./app:/app/app:ro
    environment:
      - LOG_LEVEL=DEBUG
      - FLASK_DEBUG=1
    command: ["python", "-m", "flask", "--app", "app.main", "run",
              "--host", "0.0.0.0", "--port", "5000", "--reload"]
```

Add `docker-compose.override.yml` to `.gitignore` if it contains any local paths or
credentials. Commit a `docker-compose.override.yml.example` instead.

Common commands:

```bash
# Start everything
docker compose up --build

# Start in background
docker compose up -d --build

# Tail logs from just the app
docker compose logs -f app

# Run a one-off command (e.g. a migration script)
docker compose run --rm app python scripts/run_migration.py

# Tear down and remove volumes
docker compose down -v
```

---

## 9. Image scanning

Scan images for known CVEs before pushing to a registry or deploying. Run scanning in CI
so vulnerabilities are caught automatically.

### trivy (recommended for CI)

```bash
# Install (macOS)
brew install aquasecurity/trivy/trivy

# Scan a locally built image
trivy image my-internal-tool:local

# Fail the build if HIGH or CRITICAL CVEs are found (use in CI)
trivy image --exit-code 1 --severity HIGH,CRITICAL my-internal-tool:local

# Scan and output SARIF for GitHub Actions
trivy image --format sarif --output trivy-results.sarif my-internal-tool:local
```

### docker scout (if using Docker Hub or Docker Desktop)

```bash
# One-time setup
docker scout quickview my-internal-tool:local

# Get actionable recommendations
docker scout recommendations my-internal-tool:local
```

### In CI (GitHub Actions example)

```yaml
- name: Build image
  run: docker build -t my-internal-tool:${{ github.sha }} .

- name: Scan for CVEs
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: my-internal-tool:${{ github.sha }}
    format: sarif
    output: trivy-results.sarif
    severity: HIGH,CRITICAL
    exit-code: "1"

- name: Upload SARIF
  uses: github/codeql-action/upload-sarif@v3
  if: always()
  with:
    sarif_file: trivy-results.sarif
```

Scanning catches:
- Known CVEs in base image OS packages
- Known CVEs in Python dependencies (cross-check with `pip-audit` or `safety`)
- Outdated base image tags

Schedule weekly rescans of published images even without code changes — new CVEs are
disclosed continuously.

---

## 10. Complete production Dockerfile

A full, annotated, production-ready Dockerfile for a Python Flask internal tool.

```dockerfile
# =============================================================================
# Stage 1 — builder
# Install Python dependencies in a throw-away build environment.
# Build tools (gcc, etc.) stay in this stage and never reach the final image.
# =============================================================================
FROM python:3.12.9-slim-bookworm AS builder

WORKDIR /build

# Install build-time system dependencies (only what pip needs to compile wheels)
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      gcc \
      libpq-dev \
 && rm -rf /var/lib/apt/lists/*

# Copy requirements first — cached as long as requirements.txt is unchanged.
# Changing source code does not bust this layer.
COPY requirements.txt .

# --prefix=/install puts packages in a relocatable directory we can COPY later
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# =============================================================================
# Stage 2 — final
# Minimal runtime image. No build tools, no apt caches, no test code.
# =============================================================================
FROM python:3.12.9-slim-bookworm AS final

# Runtime system libraries only (e.g. libpq for psycopg2; omit if not needed)
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libpq5 \
 && rm -rf /var/lib/apt/lists/*

# Copy installed Python packages from builder
COPY --from=builder /install /usr/local

WORKDIR /app

# Copy application source — order matters for cache efficiency
COPY src/     ./src/
COPY app/     ./app/
COPY scripts/ ./scripts/

# Build metadata — visible in 'docker inspect'; safe to bake in
ARG APP_VERSION=unknown
ARG GIT_SHA=unknown
LABEL app.name="my-internal-tool" \
      app.version="${APP_VERSION}" \
      app.git-sha="${GIT_SHA}" \
      maintainer="your-team@example.com"

# Non-secret runtime configuration — visible in 'docker inspect'
# Secrets (tokens, passwords) must be injected at runtime, not here.
ENV LOG_LEVEL=INFO \
    PORT=5000 \
    WORKERS=2 \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Create a non-root user; the app runs as this user at runtime
RUN useradd --system --no-create-home --shell /usr/sbin/nologin appuser \
 && chown -R appuser:appuser /app

USER appuser

# Health check — verifies the HTTP server is responding, not just that the
# process is alive. Adjust --start-period to match your app's startup time.
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD python -c \
    "import urllib.request; urllib.request.urlopen('http://localhost:${PORT}/health')" \
  || exit 1

EXPOSE ${PORT}

# Gunicorn in production: multiple workers, graceful shutdown, access log to stdout.
# Replace 'app.main:create_app()' with your actual Flask application factory.
CMD ["sh", "-c", \
  "gunicorn \
    --bind 0.0.0.0:${PORT} \
    --workers ${WORKERS} \
    --timeout 60 \
    --access-logfile - \
    --error-logfile - \
    'app.main:create_app()'"]
```

**Build and run:**

```bash
# Build with version metadata
docker build \
  --build-arg APP_VERSION=1.4.2 \
  --build-arg GIT_SHA=$(git rev-parse --short HEAD) \
  -t my-internal-tool:1.4.2 \
  .

# Run with secrets injected at runtime (never -e TOKEN=hardcoded in scripts)
docker run --rm \
  -e JIRA_TOKEN="$JIRA_TOKEN" \
  -e JIRA_BASE_URL="$JIRA_BASE_URL" \
  -p 5000:5000 \
  my-internal-tool:1.4.2

# Or mount a config file as a read-only volume (useful for local dev)
docker run --rm \
  -v "$(pwd)/config.yaml:/app/config.yaml:ro" \
  -p 5000:5000 \
  my-internal-tool:1.4.2
```

---

## Quick-reference checklist

Before pushing an image to a registry:

- [ ] Base image pinned to full version tag (not `latest`, not just `3.12`)
- [ ] Multi-stage build — build tools not in final image
- [ ] `requirements.txt` copied and installed before source code
- [ ] Non-root user created and set with `USER`
- [ ] `.dockerignore` excludes `config.yaml`, `.env`, `.venv/`, `tests/`, `.git/`
- [ ] No secrets in `ARG`, `ENV`, or `LABEL` instructions
- [ ] `HEALTHCHECK` defined
- [ ] `PYTHONUNBUFFERED=1` set (logs go to stdout immediately)
- [ ] `trivy image --severity HIGH,CRITICAL` passes with exit code 0
- [ ] `docker run --rm myimage whoami` prints the non-root user name
- [ ] `docker run --rm myimage find /app -name "config.yaml"` returns nothing
