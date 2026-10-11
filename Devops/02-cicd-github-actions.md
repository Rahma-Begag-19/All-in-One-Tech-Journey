# 🔄 CI/CD with GitHub Actions, GHCR & a Self-Hosted Runner

> Based on my project: [fastapi-docker-cicd](https://github.com/Rahma-Begag-19/fastapi-docker-cicd)
> Every push to `main` → tests → builds images → pushes to GHCR → deploys on my own machine.

---

## 1. What is CI/CD?

- **CI (Continuous Integration):** on every push, automatically validate the code (install deps, compile, test) so broken code never reaches `main`.
- **CD (Continuous Deployment):** after CI passes, automatically build, publish and deploy the new version — no manual `docker build` on the server.

My pipeline:

```javascript
git push to main
      │
      ▼
┌─────────────┐   fails → pipeline stops
│  1. test    │  install Python deps, compile the app (ubuntu-latest)
└─────────────┘
      │
      ▼
┌──────────────────┐  only on push to main (not PRs)
│ 2. docker-build  │  build images → push to GHCR (ubuntu-latest)
└──────────────────┘
      │
      ▼
┌──────────────┐
│  3. deploy   │  pull images → restart stack (self-hosted runner)
└──────────────┘
```

---

## 2. Trigger & permissions

```yaml
name: CI and CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read
```

- Runs on pushes **and** PRs to `main` (so PRs get tested without deploying anything).
- Top-level `permissions: contents: read` follows the principle of least privilege — each job escalates only what it needs.

---

## 3. Job 1 — `test`

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - name: Install dependencies
        working-directory: backend
        run: pip install -r requirements.txt
      - name: Check application
        working-directory: backend
        run: python -m compileall app
```

- `runs-on: ubuntu-latest` = a fresh GitHub-hosted VM.
- `working-directory` scopes commands to the backend folder.
- `python -m compileall app` byte-compiles all modules — a cheap smoke test that catches syntax errors immediately.

---

## 4. Job 2 — `docker-build` (push to GHCR)

```yaml
  docker-build:
    needs: test                                   # run only if tests pass
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    permissions:
      contents: read
      packages: write                           # needed to push to GHCR
    steps:
      - uses: actions/checkout@v4

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}   # auto-generated token!

      - name: Build and push backend image
        run: |
          docker build -t crm-backend-final ./backend
          docker tag crm-backend-final ghcr.io/rahma-begag-19/fastapi-docker-cicd/backend:latest
          docker tag crm-backend-final ghcr.io/rahma-begag-19/fastapi-docker-cicd/backend:${{ github.sha }}
          docker push ghcr.io/rahma-begag-19/fastapi-docker-cicd/backend:latest
          docker push ghcr.io/rahma-begag-19/fastapi-docker-cicd/backend:${{ github.sha }}
```

### Key concepts

- **`needs: test`** — job dependencies create the pipeline chain.
- **`if:`** — deploy-worthy work only happens on real merges to `main`, not on PRs.
- **`secrets.GITHUB_TOKEN`** — GitHub injects a temporary token automatically; with `packages: write` it can push to the repo's container registry. No personal passwords in CI!
- **Two tags per build:** `latest` (what prod pulls) and `${{ github.sha }}` (immutable — lets you roll back to an exact commit).
- Same pattern for the frontend image.

---

## 5. Job 3 — `deploy` (self-hosted runner)

```yaml
  deploy:
    needs: docker-build
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: self-hosted          # ← runs ON my machine, not GitHub's
    permissions:
      contents: read
      packages: read
    env:
      DEPLOY_DIR: /home/rahma/.../fastapi-docker-cicd
    steps:
      - name: Validate deployment configuration
        run: |
          test -f "$DEPLOY_DIR/.env" || { echo "Deployment .env file is missing."; exit 1; }
          docker compose --project-name fastapi-docker-cicd \
            --env-file "$DEPLOY_DIR/.env" \
            -f "$GITHUB_WORKSPACE/docker-compose.prod.yml" config --quiet
      - name: Pull application images
        run: docker compose ... pull backend frontend
      - name: Update production containers
        run: docker compose ... up -d --no-build --pull never --remove-orphans
      - name: Verify deployment
        run: docker compose ... ps
```

Why a **self-hosted runner**? The deployment target is my local Linux machine, which GitHub's cloud runners can't reach. So the runner agent runs on that machine, and the job executes right where the containers live.

The deploy steps, in order:

1. **Validate** — confirm `.env` exists and the compose file renders (`config --quiet`). Fails fast before touching anything.
2. **Pull** — download the freshly published `latest` images from GHCR.
3. **Update** — recreate containers with the new images. Flags matter:

- `--no-build` — never build on the server (CI already built it)
- `--pull never` — use exactly what we just pulled (no surprise re-pulls)
- `--remove-orphans` — clean up containers from removed services

4. **Verify** — `ps` lists the running stack as a final sanity check.

The extra flags `--project-name`, `--env-file` and `-f` pin everything: correct stack name, correct env file on the server, correct prod compose file from the repo.

### Setting up a self-hosted runner (summary)

1. Repo → **Settings → Actions → Runners → New self-hosted runner**.
2. Run the generated `config.sh` commands on your machine (I used my Kali Linux box).
3. Start it as a service so it survives reboots:

```bash
   ./svc.sh install
   ./svc.sh start
```

4. Test it with a minimal workflow that prints `whoami`, `hostname`, `docker --version` — exactly what my [`runner-test.yml`](https://github.com/Rahma-Begag-19/fastapi-docker-cicd/blob/main/.github/workflows/runner-test.yml) does.

---

## 6. Security notes

- The self-hosted runner has access to your machine — only run workflows from a repo **you** control, and prefer `runs-on: self-hosted` only for the deploy job (build/test stay on GitHub's VMs, isolated from your machine).
- `.env` lives only on the deployment machine, referenced via `--env-file` — never committed.
- The auto `GITHUB_TOKEN` expires when the workflow ends — far safer than long-lived PATs.

---

## 7. Troubleshooting

| Symptom | Fix |
| --- | --- |
| `denied: installation not allowed` on push | Job needs `packages: write` permission |
| Deploy job never runs | Check the `if:` — PRs don't deploy, only pushes to `main` |
| Runner is offline | Restart the service: `sudo ./svc.sh start` |
| Workflow can't find docker on runner | Install Docker on the runner machine and give its user docker access |
| Old code after deploy | Make sure the deploy step uses `--pull never` **after** an explicit `pull`, so `latest` is actually new |