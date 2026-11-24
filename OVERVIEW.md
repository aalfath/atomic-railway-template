# Deploy and Host Atomic on Railway

Atomic is an open-source, self-hosted personal knowledge base. You write markdown notes ("atoms"); Atomic chunks and embeds them, tags them with an LLM and links them by meaning. On top of that it builds wiki articles with citations, a spatial canvas of your notes, an agentic chat over your knowledge and an MCP server for AI clients.

## About Hosting Atomic

This template runs the official Atomic 1.45.0 all-in-one image (Rust `atomic-server`, the web app and nginx) as one service, with every note, setting and API token in SQLite on a Railway volume at `/data`. Railway generates `ATOMIC_SETUP_TOKEN`, so only you can claim the new instance: open the public URL, choose "Local server", paste the token from the service's Variables tab, and save the API token Atomic shows you once. Then pick an AI provider in the onboarding (OpenRouter, any OpenAI-compatible API, or Ollama) and paste your own API key there. Embeddings, tagging, wiki and chat all use that provider. Atomic runs in about 50–100 MB of RAM, so it fits Railway's 0.5 GB Free plan.

## Common Use Cases

* A private second brain: notes, clippings and RSS items that link themselves by meaning
* Semantic search, wiki synthesis and chat with citations over your own notes
* Long-term memory for AI assistants (Claude, Cursor and others) through Atomic's MCP endpoint

## Dependencies for Atomic Hosting

* An API key for an LLM provider: OpenRouter, an OpenAI-compatible API, or an Ollama server you can reach (entered in Atomic's settings, not in Railway)
* A Railway volume at `/data` (included)

### Deployment Dependencies

* Atomic source and releases: https://github.com/kenforthewin/atomic (release v1.45.0)
* Self-hosting docs: https://github.com/kenforthewin/atomic/tree/main/docs/manual/self-hosting
* Template repo: https://github.com/aalfath/atomic-railway-template

### Implementation Details

Service **Atomic**: the official image `ghcr.io/kenforthewin/atomic:1.45.0`, pinned by digest, built from our template repo. A small start script runs `atomic-server` on loopback and nginx on `PORT` (8080), and stops the container with an error if either one dies, so Railway's restart policy restarts it. It also sizes nginx workers, tokio threads and SQLite caches to the service's CPU and memory. Health check: `/health`.

Variables: `ATOMIC_SETUP_TOKEN` (generated; used once to claim the instance), `PUBLIC_URL` (your Railway domain, for OAuth and MCP discovery) and `PORT`.

Connect an MCP client to `https://YOUR-DOMAIN/mcp` with `Authorization: Bearer YOUR-ATOMIC-API-TOKEN` (create extra tokens under Settings), for example:

```json
{ "mcpServers": { "atomic": { "url": "https://YOUR-DOMAIN/mcp", "headers": { "Authorization": "Bearer YOUR-ATOMIC-API-TOKEN" } } } }
```

Clients that support OAuth can use `https://YOUR-DOMAIN/mcp` directly and sign in through Atomic.

Updates: the template builds from a GitHub repo, so when we bump the Atomic version Railway shows you an "update available" notice. Read the repo's CHANGELOG.md first, then apply it. Your data stays on the volume. Back up the volume before major upgrades.

## Why Deploy Atomic on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Atomic on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
