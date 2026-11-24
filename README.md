[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/atomic-2?utm_medium=integration&utm_source=button&utm_campaign=atomic)

# Atomic on Railway

One-click Railway template for [Atomic](https://github.com/kenforthewin/atomic) **1.45.0**, a self-hosted personal knowledge base that links markdown notes by meaning and adds wiki synthesis, a canvas, agentic chat and an MCP server.

## What it deploys

| Service | What it does |
|---|---|
| **Atomic** | Official all-in-one image `ghcr.io/kenforthewin/atomic:1.45.0@sha256:b63fe363…` (Rust `atomic-server` + web UI + nginx), built from this repo. Data (SQLite databases, settings, API tokens) on a volume at `/data`. Health check `/health`. |

Fits Railway's Free plan (0.5 GB RAM, 1 vCPU): idle about 40 MB, under load around 100 MB.

## Variables

| Variable | Value | Notes |
|---|---|---|
| `ATOMIC_SETUP_TOKEN` | `${{secret(32)}}` | Generated. Paste it once in the setup screen to claim the instance. Without it, the service refuses to start. |
| `PUBLIC_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Used for OAuth and MCP discovery. |
| `PORT` | `8080` | Public port (nginx). |

Nothing to fill in at deploy time. Your LLM key goes into Atomic's own settings after you claim it.

## After deploy

1. Open the service's public URL.
2. Choose **Local server**, paste `ATOMIC_SETUP_TOKEN` from the service's Variables tab, and save the API token Atomic shows you (it's shown once).
3. Pick an AI provider (OpenRouter, an OpenAI-compatible API or Ollama) and enter your key and models.
4. Optional: connect an MCP client to `https://YOUR-DOMAIN/mcp` with `Authorization: Bearer <your Atomic API token>`.

## How updates reach you

The service builds from this repo's `main` branch. When we bump the Atomic version here, Railway shows deployers an "update available" notice. Check `CHANGELOG.md` (breaking changes are listed first), then apply it from your dashboard. Data on the volume is kept.

## Files

- `Dockerfile`: the pinned upstream image plus our start script and nginx config.
- `start.sh`: runs `atomic-server` (loopback) and nginx (`$PORT`), sizes threads and caches to the container, and exits non-zero if either process stops so Railway restarts it.
- `nginx.conf.template`: upstream's nginx routes (`/api`, `/ws`, `/mcp`, OAuth, SPA) on `$PORT`.
- `OVERVIEW.md`: the Railway marketplace overview.

Atomic is MIT-licensed by Kenneth Bergquist. This wrapper is not affiliated with the Atomic project.
